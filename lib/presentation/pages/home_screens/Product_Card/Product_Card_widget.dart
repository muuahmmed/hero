import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/product_model.dart';
import 'package:hero/data/models/cart_item_model.dart';

import '../cart_screen/cart_cubit/cart_cubit.dart';
import '../cart_screen/cart_cubit/cart_states.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFeatured;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteToggle,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.getImageUrl();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.08),
                          ],
                        ),
                      ),
                    ),

                    // Favorite Button
                    if (onFavoriteToggle != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              product.isFavorite == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: product.isFavorite == true
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                    // Stock Badge
                    if (product.stock <= 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Featured badge
                    if (isFeatured && product.stock > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 10),
                              SizedBox(width: 3),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Product Info
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price} EGP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        // Add to Cart Button
                        BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) {
                            final inCart =
                                cartState is CartLoaded &&
                                cartState.items.any(
                                  (item) => item.productId == product.id,
                                );
                            return GestureDetector(
                              onTap: product.stock > 0
                                  ? () {
                                      final cartItem = CartItem(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch,
                                        productId: product.id,
                                        productName: product.name,
                                        productImage: product.imageUrl,
                                        unitPrice: product.price,
                                        quantity: 1,
                                        addedAt: DateTime.now(),
                                      );
                                      context.read<CartCubit>().addToCart(
                                        cartItem,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${product.name} added to cart!',
                                          ),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: const Color(
                                            0xFF3B82F6,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: product.stock <= 0
                                      ? Colors.grey[200]
                                      : inCart
                                      ? const Color(0xFF3B82F6)
                                      : const Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  inCart
                                      ? Icons.shopping_cart
                                      : Icons.add_shopping_cart,
                                  size: 15,
                                  color: product.stock <= 0
                                      ? Colors.grey
                                      : inCart
                                      ? Colors.white
                                      : const Color(0xFF3B82F6),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
