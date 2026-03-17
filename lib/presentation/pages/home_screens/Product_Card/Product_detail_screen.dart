import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/product_model.dart';
import 'package:hero/data/models/cart_item_model.dart';
import 'package:hero/data/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cart_screen/cart_cubit/cart_cubit.dart';

// ── Review Model ──────────────────────────────────────────────────────────────
class ProductReview {
  final int id;
  final int userId;
  final int productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? userName;

  const ProductReview({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      productId: json['product_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['users'] != null ? json['users']['name'] as String? : null,
    );
  }
}

// ── Review Service ────────────────────────────────────────────────────────────
class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();

  Future<List<ProductReview>> getProductReviews(int productId) async {
    final response = await _supabase
        .from('reviews')
        .select('*, users(name)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ProductReview.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<double> getAverageRating(int productId) async {
    final response = await _supabase
        .from('reviews')
        .select('rating')
        .eq('product_id', productId);

    final list = response as List;
    if (list.isEmpty) return 0.0;
    final total = list.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
    return total / list.length;
  }

  Future<ProductReview?> getMyReview(int productId) async {
    final userId = await _profileService.getUserDbId();
    if (userId == null) return null;

    final response = await _supabase
        .from('reviews')
        .select('*, users(name)')
        .eq('product_id', productId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProductReview.fromJson(response as Map<String, dynamic>);
  }

  Future<void> submitReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    await _profileService.submitReview(
      productId: productId,
      rating: rating,
      comment: comment,
    );
  }

  Future<void> deleteReview(int reviewId) async {
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }
}

// ── Product Detail Screen ─────────────────────────────────────────────────────
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isTogglingWishlist = false;

  final _profileService = ProfileService();
  final _reviewService = ReviewService();

  List<ProductReview> _reviews = [];
  double _avgRating = 0.0;
  ProductReview? _myReview;
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadWishlistStatus();
    _loadReviews();
  }

  Future<void> _loadWishlistStatus() async {
    try {
      final inWishlist = await _profileService.isInWishlist(widget.product.id);
      if (mounted) setState(() => _isFavorite = inWishlist);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = widget.product.isFavorite ?? false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final results = await Future.wait([
        _reviewService.getProductReviews(widget.product.id),
        _reviewService.getAverageRating(widget.product.id),
        _reviewService.getMyReview(widget.product.id),
      ]);
      if (mounted) {
        setState(() {
          _reviews = results[0] as List<ProductReview>;
          _avgRating = results[1] as double;
          _myReview = results[2] as ProductReview?;
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isTogglingWishlist) return;
    setState(() => _isTogglingWishlist = true);
    final wasInWishlist = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);
    try {
      await _profileService.toggleWishlist(widget.product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isFavorite ? '❤️ Added to wishlist' : 'Removed from wishlist'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _isFavorite ? Colors.red[400] : Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = wasInWishlist);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isTogglingWishlist = false);
    }
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

  // ── Review Bottom Sheet ───────────────────────────────────────────────────
  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        existingReview: _myReview,
        onSubmit: (rating, comment) async {
          await _reviewService.submitReview(
            productId: widget.product.id,
            rating: rating,
            comment: comment,
          );
          await _loadReviews();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('✅ Review submitted!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
        onDelete: _myReview != null
            ? () async {
          await _reviewService.deleteReview(_myReview!.id);
          await _loadReviews();
        }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOutOfStock = product.stock <= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).iconTheme.color,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.getImageUrl(),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF3B82F6))),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: _isTogglingWishlist
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
                )
                    : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey[600],
                  ),
                  onPressed: _toggleWishlist,
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
                  // ── Name & Price ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(product.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                      ),
                      const SizedBox(width: 16),
                      Text('${product.price.toStringAsFixed(0)} EGP',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6))),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Rating Summary ────────────────────────────────────────
                  if (!_loadingReviews)
                    GestureDetector(
                      onTap: () {
                        // Scroll to reviews section
                      },
                      child: Row(
                        children: [
                          _StarDisplay(rating: _avgRating, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _avgRating > 0
                                ? '${_avgRating.toStringAsFixed(1)} (${_reviews.length} review${_reviews.length != 1 ? 's' : ''})'
                                : 'No reviews yet',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Info Chips ────────────────────────────────────────────
                  Wrap(
                    spacing: 8, runSpacing: 8,
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

                  // ── Description ───────────────────────────────────────────
                  const Text('Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),

                  // ── Quantity ──────────────────────────────────────────────
                  if (!isOutOfStock) ...[
                    const SizedBox(height: 24),
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
                        Text('Total: ${(product.price * _quantity).toStringAsFixed(0)} EGP',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6))),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Reviews Section ───────────────────────────────────────
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isOutOfStock ? _buildAddToCartBar(context) : _buildOutOfStockBar(),
    );
  }

  // ── Reviews Section ───────────────────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews (${_reviews.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _openReviewSheet,
              icon: Icon(_myReview != null ? Icons.edit : Icons.rate_review_outlined, size: 18),
              label: Text(_myReview != null ? 'Edit Review' : 'Write Review'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Rating breakdown
        if (!_loadingReviews && _reviews.isNotEmpty) ...[
          _RatingBreakdown(reviews: _reviews, avgRating: _avgRating),
          const SizedBox(height: 16),
        ],

        // Reviews list
        if (_loadingReviews)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ))
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('No reviews yet', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Be the first to review!',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _ReviewTile(
              review: _reviews[i],
              isMyReview: _myReview?.id == _reviews[i].id,
              onDelete: _myReview?.id == _reviews[i].id
                  ? () async {
                await _reviewService.deleteReview(_reviews[i].id);
                await _loadReviews();
              }
                  : null,
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAddToCartBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: Text('Add${_quantity > 1 ? " ($_quantity)" : ""} to Cart',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).cardColor,
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

// ── Rating Breakdown Widget ───────────────────────────────────────────────────
class _RatingBreakdown extends StatelessWidget {
  final List<ProductReview> reviews;
  final double avgRating;

  const _RatingBreakdown({required this.reviews, required this.avgRating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Average number
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6)),
              ),
              _StarDisplay(rating: avgRating, size: 16),
              const SizedBox(height: 4),
              Text('${reviews.length} reviews',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(width: 20),
          // Bars
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = reviews.where((r) => r.rating == star).length;
                final percent = reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review Tile ───────────────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final ProductReview review;
  final bool isMyReview;
  final VoidCallback? onDelete;

  const _ReviewTile({
    required this.review,
    required this.isMyReview,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (review.userName?.isNotEmpty == true ? review.userName![0] : 'U').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.userName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (isMyReview) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('You',
                            style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _StarDisplay(rating: review.rating.toDouble(), size: 14),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(review.comment!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[300]),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Review Sheet ──────────────────────────────────────────────────────────────
class _ReviewSheet extends StatefulWidget {
  final ProductReview? existingReview;
  final Future<void> Function(int rating, String? comment) onSubmit;
  final VoidCallback? onDelete;

  const _ReviewSheet({
    this.existingReview,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating;
  late TextEditingController _commentCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _commentCtrl = TextEditingController(text: widget.existingReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existingReview != null ? 'Edit Your Review' : 'Write a Review',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Star selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: star <= _rating ? 40 : 32,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(_getRatingLabel(_rating),
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),

            const SizedBox(height: 16),

            // Comment field
            TextFormField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                if (widget.onDelete != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                if (widget.onDelete != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        await widget.onSubmit(
                          _rating,
                          _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
                        );
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.existingReview != null ? 'Update Review' : 'Submit Review',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}

// ── Star Display Widget ───────────────────────────────────────────────────────
class _StarDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const _StarDisplay({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        if (star <= rating) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (star - 0.5 <= rating) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
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

// ── Quantity Button ───────────────────────────────────────────────────────────
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
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isEnabled ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.grey[300]!),
        ),
        child: Icon(icon, size: 20,
            color: isEnabled ? const Color(0xFF3B82F6) : Colors.grey[400]),
      ),
    );
  }
}