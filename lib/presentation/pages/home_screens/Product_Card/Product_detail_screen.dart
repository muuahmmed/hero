import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/product_model.dart';
import 'package:hero/data/models/cart_item_model.dart';
import '../cart_screen/cart_cubit/cart_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite ?? false;
  }

  void _addToCart(BuildContext context) {
    context.read<CartCubit>().addToCart(CartItem(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: widget.product.id,
      productName: widget.product.name,
      productImage: widget.product.imageUrl,
      unitPrice: widget.product.price,
      quantity: _quantity,
      addedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOutOfStock = product.stock <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.getImageUrl(),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF3B82F6)),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.fitness_center,
                          size: 80, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white.withOpacity(0.8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // ✅ Local state only — no HomeCubit lookup
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() => _isFavorite = !_isFavorite);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_isFavorite ? '❤️ Added to wishlist' : 'Removed from wishlist'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(product.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                      ),
                      const SizedBox(width: 16),
                      Text('${product.price.toStringAsFixed(0)} EGP',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: isOutOfStock ? Icons.cancel : Icons.check_circle,
                        label: isOutOfStock ? 'Out of Stock' : '${product.stock} in stock',
                        color: isOutOfStock ? Colors.red : Colors.green,
                      ),
                      if (product.company != null)
                        _InfoChip(icon: Icons.business, label: product.company!, color: Colors.orange),
                      if (product.size != null)
                        _InfoChip(icon: Icons.straighten, label: product.size!, color: Colors.purple),
                      if (product.isEgyptian == true)
                        const _InfoChip(icon: Icons.flag, label: 'Egyptian Product', color: Colors.teal),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text('Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),

                  const SizedBox(height: 24),

                  if (!isOutOfStock) ...[
                    const Text('Quantity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuantityButton(
                          icon: Icons.remove,
                          onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text('$_quantity',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        _QuantityButton(
                          icon: Icons.add,
                          onTap: _quantity < product.stock ? () => setState(() => _quantity++) : null,
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${(product.price * _quantity).toStringAsFixed(0)} EGP',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isOutOfStock ? _buildAddToCartBar(context) : _buildOutOfStockBar(),
    );
  }

  Widget _buildAddToCartBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                _addToCart(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${widget.product.name} added to cart!'),
                  backgroundColor: const Color(0xFF3B82F6),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 1),
                ));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                _addToCart(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${widget.product.name} added to cart!'),
                  backgroundColor: const Color(0xFF3B82F6),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: Text(
                'Add${_quantity > 1 ? " ($_quantity)" : ""} to Cart',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfStockBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text('Out of Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Icon(icon, size: 20, color: isEnabled ? const Color(0xFF3B82F6) : Colors.grey[400]),
      ),
    );
  }
}