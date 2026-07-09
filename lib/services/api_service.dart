import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  late PersistCookieJar _cookieJar;
  bool _initialized = false;

  static const String baseUrl = 'https://sajhya.com/physio-api';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.physio_cookies/'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.responseType = ResponseType.plain;
  }

  Future<void> _ensureCsrf() async => _dio.get('/csrf/');

  Future<String> _csrf() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    final c = cookies.firstWhere(
      (c) => c.name == 'csrftoken',
      orElse: () => Cookie('csrftoken', ''),
    );
    return c.value;
  }

  Map<String, dynamic> _decode(dynamic raw) {
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    return raw as Map<String, dynamic>;
  }

  // ── auth ──────────────────────────────────────────────────────────────────

  // ── user cache (SharedPreferences) ───────────────────────────────────────

  static const _kUser = 'physio_user';

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
  }

  // ── auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    await _ensureCsrf();
    final csrf = await _csrf();
    final r = await _dio.post(
      '/login/',
      data: {'username': username, 'password': password},
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    final result = _decode(r.data);
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user'] as Map<String, dynamic>);
    }
    return result;
  }

  Future<void> logout() async {
    try {
      final csrf = await _csrf();
      await _dio.post('/logout/', options: Options(headers: {'X-CSRFToken': csrf}));
    } finally {
      await _cookieJar.deleteAll();
      await _clearUser();
    }
  }

  Future<Map<String, dynamic>> me() async {
    final r = await _dio.get('/me/');
    final result = _decode(r.data);
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user'] as Map<String, dynamic>);
    }
    return result;
  }

  // ── dashboard ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final r = await _dio.get('/dashboard/');
    return _decode(r.data);
  }

  // ── patients ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPatients({String? q}) async {
    final r = await _dio.get('/patients/', queryParameters: q != null && q.isNotEmpty ? {'q': q} : null);
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['patients']);
  }

  Future<Map<String, dynamic>> createPatient({
    required String name,
    required String contact,
    required String diagnosis,
    int? clinicId,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/patients/',
      data: {
        'patient_name': name,
        'patient_contact': contact,
        'patient_diagnosis': diagnosis,
        if (clinicId != null) 'clinic_id': clinicId,
      },
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  Future<Map<String, dynamic>> getPatientDetail(String patientCode) async {
    final r = await _dio.get('/patients/$patientCode/');
    return _decode(r.data);
  }

  // ── clinics ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getClinics() async {
    final r = await _dio.get('/clinics/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['clinics']);
  }

  Future<Map<String, dynamic>> getClinicDetail(int clinicId) async {
    final r = await _dio.get('/clinics/$clinicId/');
    return _decode(r.data);
  }

  Future<Map<String, dynamic>> createClinic({
    required String name,
    required String address,
    required String phone,
    String? panNumber,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/clinics/',
      data: {
        'clinic_name': name,
        'address': address,
        'phone': phone,
        if (panNumber != null && panNumber.isNotEmpty) 'pan_number': panNumber,
      },
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  // ── home visits (find-physio bookings) ───────────────────────────────────

  Future<List<Map<String, dynamic>>> getHomeVisits({String? status}) async {
    final r = await _dio.get(
      '/home-visits/',
      queryParameters: status != null && status.isNotEmpty ? {'status': status} : null,
    );
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['home_visits']);
  }

  Future<Map<String, dynamic>> updateHomeVisitStatus(
    int bookingId, {
    required String status,
    String? notes,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/home-visits/$bookingId/status/',
      data: {'status': status, if (notes != null) 'notes': notes},
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  // ── shop (marketplace) ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getShopCategories() async {
    final r = await _dio.get('/shop/categories/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['categories']);
  }

  Future<List<Map<String, dynamic>>> getShopProducts({int? categoryId, String? search}) async {
    final r = await _dio.get('/shop/products/', queryParameters: {
      if (categoryId != null) 'category': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['products']);
  }

  Future<List<Map<String, dynamic>>> getShopOrders() async {
    final r = await _dio.get('/shop/orders/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['orders']);
  }

  Future<Map<String, dynamic>> createShopOrder({
    required List<Map<String, dynamic>> items,
    required String customerPhone,
    required String deliveryAddress,
    String? customerName,
    String? customerEmail,
    String? notes,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/shop/orders/',
      data: {
        'items': items,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        if (customerName != null) 'customer_name': customerName,
        if (customerEmail != null) 'customer_email': customerEmail,
        if (notes != null) 'notes': notes,
      },
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  // ── exercises ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRegions() async {
    final r = await _dio.get('/regions/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['regions']);
  }

  Future<List<Map<String, dynamic>>> getExercises({required int subregionId}) async {
    final r = await _dio.get('/exercises/', queryParameters: {'subregion_id': subregionId});
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['exercises']);
  }

  // ── prescriptions ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPrescriptions(String patientCode) async {
    final r = await _dio.get('/prescriptions/$patientCode/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['prescriptions']);
  }

  Future<Map<String, dynamic>> createPrescription(
    String patientCode,
    List<int> exerciseIds,
  ) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/prescriptions/$patientCode/',
      data: {'exercise_ids': exerciseIds},
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  // ── sessions ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSessions(String patientCode) async {
    final r = await _dio.get('/sessions/$patientCode/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['sessions']);
  }

  Future<Map<String, dynamic>> addSession(
    String patientCode, {
    required String sessionNote,
    String? preNotes,
    String? treatmentResponse,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/sessions/$patientCode/',
      data: {
        'session_note': sessionNote,
        if (preNotes != null) 'pre_notes': preNotes,
        if (treatmentResponse != null) 'treatment_response': treatmentResponse,
      },
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  // ── referrals ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReferrals() async {
    final r = await _dio.get('/referrals/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['referrals']);
  }

  Future<Map<String, dynamic>> createReferral({
    required String patientName,
    required String patientDiagnosis,
    required String reason,
    String? patientContact,
    String? notes,
    int? referredToId,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/referrals/',
      data: {
        'patient_name': patientName,
        'patient_diagnosis': patientDiagnosis,
        'reason': reason,
        if (patientContact != null) 'patient_contact': patientContact,
        if (notes != null) 'notes': notes,
        if (referredToId != null) 'referred_to_id': referredToId,
      },
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  Future<Map<String, dynamic>> searchReferral(String code) async {
    final r = await _dio.get('/referrals/search/', queryParameters: {'code': code});
    return _decode(r.data);
  }

  Future<Map<String, dynamic>> acceptReferral(
    String referralCode, {
    required String patientName,
    required String patientDiagnosis,
    String? patientContact,
  }) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/referrals/$referralCode/accept/',
      data: {
        'patient_name': patientName,
        'patient_diagnosis': patientDiagnosis,
        if (patientContact != null) 'patient_contact': patientContact,
      },
      options: Options(headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'}),
    );
    return _decode(r.data);
  }

  Future<Map<String, dynamic>> rejectReferral(String referralCode) async {
    final csrf = await _csrf();
    final r = await _dio.post(
      '/referrals/$referralCode/reject/',
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return _decode(r.data);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final r = await _dio.get('/users/');
    final d = _decode(r.data);
    return List<Map<String, dynamic>>.from(d['users']);
  }
}
