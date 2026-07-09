import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Home-visit booking requests made to this physio's public find-a-physio
/// profile (find_physio_app.BookingRequest, booking_type='home').
class HomeVisitScreen extends StatefulWidget {
  const HomeVisitScreen({super.key});

  @override
  State<HomeVisitScreen> createState() => _HomeVisitScreenState();
}

class _HomeVisitScreenState extends State<HomeVisitScreen> {
  static const _statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

  List<Map<String, dynamic>>? _bookings;
  String? _error;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final bookings = await ApiService().getHomeVisits(status: _statusFilter);
      if (mounted) setState(() => _bookings = bookings);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return AppColors.info;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> booking, String newStatus) async {
    try {
      await ApiService().updateHomeVisitStatus(booking['id'] as int, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as $newStatus'), backgroundColor: AppColors.success),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _openActions(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(booking['patient_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Update booking status'),
            ),
            if (booking['status'] != 'confirmed')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.info),
                title: const Text('Confirm'),
                onTap: () { Navigator.pop(context); _updateStatus(booking, 'confirmed'); },
              ),
            if (booking['status'] != 'completed')
              ListTile(
                leading: const Icon(Icons.task_alt, color: AppColors.success),
                title: const Text('Mark Completed'),
                onTap: () { Navigator.pop(context); _updateStatus(booking, 'completed'); },
              ),
            if (booking['status'] != 'cancelled')
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                title: const Text('Cancel'),
                onTap: () { Navigator.pop(context); _updateStatus(booking, 'cancelled'); },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Visit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', ''),
                  const SizedBox(width: 8),
                  for (final s in _statuses) ...[
                    _filterChip(s[0].toUpperCase() + s.substring(1), s),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: Builder(builder: (context) {
                if (_error != null) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('Could not load bookings.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                        ),
                      ),
                    ],
                  );
                }
                if (_bookings == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_bookings!.isEmpty) {
                  return ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No home visit bookings yet.', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _bookings!.length,
                  itemBuilder: (_, i) {
                    final b = _bookings![i];
                    final status = b['status']?.toString() ?? 'pending';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentOrange.withOpacity(0.1),
                          child: const Icon(Icons.home_work_outlined, color: AppColors.accentOrange),
                        ),
                        title: Text(b['patient_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['condition']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${b['preferred_date']}${b['preferred_time'] != null ? ' • ${b['preferred_time']}' : ''}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _openActions(b),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _load();
      },
    );
  }
}
