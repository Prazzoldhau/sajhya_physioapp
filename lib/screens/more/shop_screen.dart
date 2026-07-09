import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'shop_cart_screen.dart';
import 'shop_orders_screen.dart';

/// Marketplace tab, named "Shop" in the UI. Backed by marketplace_app
/// (Category/Product/Order) via the physio_api_app REST endpoints.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Map<String, dynamic>>? _products;
  List<Map<String, dynamic>> _categories = [];
  String? _error;
  int? _selectedCategory;
  final Map<int, int> _cart = {}; // productId -> quantity
  Map<int, Map<String, dynamic>> _productById = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService().getShopCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() => _error = null);
    try {
      final products = await ApiService().getShopProducts(categoryId: _selectedCategory);
      _productById = {for (final p in products) p['id'] as int: p};
      if (mounted) setState(() => _products = products);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _addToCart(int productId) {
    setState(() => _cart[productId] = (_cart[productId] ?? 0) + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _openCart() async {
    final placed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ShopCartScreen(cart: Map.of(_cart), productById: _productById)),
    );
    if (placed == true) setState(_cart.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopOrdersScreen())),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (_cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                      child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            onPressed: _cartCount > 0 ? _openCart : null,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip('All', null),
                    const SizedBox(width: 8),
                    for (final c in _categories) ...[
                      _categoryChip(c['name']?.toString() ?? '', c['id'] as int),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: Builder(builder: (context) {
                if (_error != null) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('Could not load products.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                        ),
                      ),
                    ],
                  );
                }
                if (_products == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_products!.isEmpty) {
                  return ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No products available.', style: TextStyle(color: AppColors.textMuted))),
                      ),
                    ],
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _products!.length,
                  itemBuilder: (_, i) => _productCard(_products![i]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, int? id) {
    final selected = _selectedCategory == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedCategory = id);
        _loadProducts();
      },
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final id = p['id'] as int;
    final qty = _cart[id] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_services_outlined, color: AppColors.accentTeal, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            p['name']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if ((p['category']?.toString() ?? '').isNotEmpty)
            Text(p['category'].toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rs. ${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              InkWell(
                onTap: () => _addToCart(id),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Icon(qty > 0 ? Icons.add : Icons.add_shopping_cart, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
