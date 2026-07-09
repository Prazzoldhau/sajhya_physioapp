import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class ShopCartScreen extends StatefulWidget {
  final Map<int, int> cart; // productId -> quantity
  final Map<int, Map<String, dynamic>> productById;

  const ShopCartScreen({super.key, required this.cart, required this.productById});

  @override
  State<ShopCartScreen> createState() => _ShopCartScreenState();
}

class _ShopCartScreenState extends State<ShopCartScreen> {
  late Map<int, int> _cart;
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _cart = Map.of(widget.cart);
  }

  double get _total {
    double t = 0;
    _cart.forEach((id, qty) {
      final price = double.tryParse(widget.productById[id]?['price']?.toString() ?? '0') ?? 0;
      t += price * qty;
    });
    return t;
  }

  void _updateQty(int id, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = qty;
      }
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cart.isEmpty) return;
    setState(() => _placing = true);

    try {
      final items = _cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value}).toList();
      final result = await ApiService().createShopOrder(
        items: items,
        customerPhone: _phoneCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${result['order_number']} placed!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Failed to place order'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: _cart.isEmpty
          ? const Center(child: Text('Your cart is empty.', style: TextStyle(color: AppColors.textMuted)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final entry in _cart.entries) _cartLine(entry.key, entry.value),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Rs. ${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressCtrl,
                    label: 'Delivery Address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _notesCtrl,
                    label: 'Notes (optional)',
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _placing ? null : _placeOrder,
                    child: _placing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Place Order'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _cartLine(int id, int qty) {
    final p = widget.productById[id];
    final name = p?['name']?.toString() ?? 'Product #$id';
    final price = double.tryParse(p?['price']?.toString() ?? '0') ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Rs. ${price.toStringAsFixed(2)} each'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQty(id, qty - 1)),
            Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQty(id, qty + 1)),
          ],
        ),
      ),
    );
  }
}
