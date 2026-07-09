import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({super.key});

  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> {
  List<Map<String, dynamic>>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final orders = await ApiService().getShopOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.danger;
      case 'shipped':
      case 'processing':
      case 'confirmed': return AppColors.info;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(builder: (context) {
          if (_error != null) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('Could not load orders.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            );
          }
          if (_orders == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_orders!.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No orders yet.', style: TextStyle(color: AppColors.textMuted))),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _orders!.length,
            itemBuilder: (_, i) {
              final o = _orders![i];
              final status = o['status']?.toString() ?? 'pending';
              final items = (o['items'] as List?) ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(
                    o['order_number']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13),
                  ),
                  subtitle: Text('Rs. ${o['total_amount']}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.bold)),
                  ),
                  children: [
                    for (final item in items)
                      ListTile(
                        dense: true,
                        title: Text('${item['quantity']}x ${item['product_name']}'),
                        trailing: Text('Rs. ${item['unit_price']}'),
                      ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
