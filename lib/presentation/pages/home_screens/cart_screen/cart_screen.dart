import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_cubit/cart_cubit.dart';
import 'cart_cubit/cart_states.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return TextButton(
                  onPressed: () => _showClearCartDialog(context),
                  child: const Text('Clear',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoaded && state.items.isNotEmpty) {
            return _buildCartContent(context, state);
          }
          return _buildEmptyCart(context);
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 70, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'Add products to your cart\nand they will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey[500], height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to home tab — handled via MainHomeScreen state
              // Using a simple pop or Navigator callback approach
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Browse Products',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartLoaded state) {
    final total = context.read<CartCubit>().getTotal();
    const deliveryFee = 50.0;
    final grandTotal = total + deliveryFee;
    final itemCount =
    state.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _CartItemCard(
                item: item,
                onRemove: () =>
                    context.read<CartCubit>().removeFromCart(item.productId),
                onQuantityChange: (qty) {
                  if (qty <= 0) {
                    context.read<CartCubit>().removeFromCart(item.productId);
                  } else {
                    context
                        .read<CartCubit>()
                        .updateQuantity(item.productId, qty);
                  }
                },
              );
            },
          ),
        ),
        _buildOrderSummary(context, total, grandTotal, itemCount),
      ],
    );
  }

  Widget _buildOrderSummary(
      BuildContext context, double total, double grandTotal, int itemCount) {
    const deliveryFee = 50.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _summaryRow('Items ($itemCount)', '${total.toStringAsFixed(0)} EGP'),
          const SizedBox(height: 8),
          _summaryRow(
              'Delivery', '${deliveryFee.toStringAsFixed(0)} EGP'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _summaryRow(
            'Total',
            '${grandTotal.toStringAsFixed(0)} EGP',
            isBold: true,
            valueColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showCheckoutSheet(context, grandTotal),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Checkout — ${grandTotal.toStringAsFixed(0)} EGP',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isBold ? Colors.black : Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutSheet(BuildContext context, double total) {
    final cartCubit = context.read<CartCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cartCubit,
        child: _CheckoutSheet(total: total),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Item Card
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChange;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[100],
              child: item.productImage != null &&
                  item.productImage!.isNotEmpty
                  ? Image.network(
                item.productImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.fitness_center,
                    color: Colors.grey),
              )
                  : const Icon(Icons.fitness_center, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Product',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.unitPrice.toStringAsFixed(0)} EGP each',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: () => onQuantityChange(item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: () => onQuantityChange(item.quantity + 1),
                    ),
                    const Spacer(),
                    Text(
                      '${(item.unitPrice * item.quantity).toStringAsFixed(0)} EGP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            padding: EdgeInsets.zero,
            constraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkout Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final double total;
  const _CheckoutSheet({required this.total});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Checkout',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                            const Color(0xFF3B82F6).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order Total',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${widget.total.toStringAsFixed(0)} EGP',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delivery Address
                    const Text('Delivery Address',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter your full delivery address...',
                        prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF3B82F6)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 2),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your address'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: Color(0xFF3B82F6)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 2),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your phone'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    const Text('Payment Method',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _PaymentOption(
                      value: 'cash',
                      groupValue: _paymentMethod,
                      label: 'Cash on Delivery',
                      icon: Icons.money,
                      color: Colors.green,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 8),
                    _PaymentOption(
                      value: 'card',
                      groupValue: _paymentMethod,
                      label: 'Credit / Debit Card',
                      icon: Icons.credit_card,
                      color: Colors.blue,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 8),
                    _PaymentOption(
                      value: 'vodafone',
                      groupValue: _paymentMethod,
                      label: 'Vodafone Cash',
                      icon: Icons.phone_android,
                      color: Colors.red,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Order notes (optional)',
                        prefixIcon: const Icon(Icons.note_outlined,
                            color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Place Order button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  'Place Order — ${widget.total.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPlacingOrder = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.read<CartCubit>().clearCart();
      Navigator.pop(context); // close sheet
      _showSuccessDialog(context);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your order of ${widget.total.toStringAsFixed(0)} EGP has been placed successfully. We\'ll contact you shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.07) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[500], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                  isSelected ? color : Colors.black87,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
