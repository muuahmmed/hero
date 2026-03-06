import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_models.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Get current user's integer DB id from public.users ──────────────────
  Future<int?> _getUserDbId() async {
    final authUid = _supabase.auth.currentUser?.id;
    if (authUid == null) return null;
    final res = await _supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authUid)
        .single();
    return res['id'] as int?;
  }

  // ── Profile update ───────────────────────────────────────────────────────
  Future<void> updateProfile({String? name, String? phone}) async {
    final authUid = _supabase.auth.currentUser?.id;
    if (authUid == null) throw Exception('Not authenticated');
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null && name.isNotEmpty) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    await _supabase.from('users').update(updates).eq('auth_user_id', authUid);
  }

  // ── Change password via Supabase Auth ────────────────────────────────────
  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Wishlist ─────────────────────────────────────────────────────────────
  Future<List<WishlistItem>> getWishlist() async {
    final userId = await _getUserDbId();
    if (userId == null) return [];
    final res = await _supabase
        .from('wishlist')
        .select('*, products(id, name, price, image_url, stock, company)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((j) => WishlistItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isInWishlist(int productId) async {
    final userId = await _getUserDbId();
    if (userId == null) return false;
    final res = await _supabase
        .from('wishlist')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId);
    return (res as List).isNotEmpty;
  }

  Future<void> addToWishlist(int productId) async {
    final userId = await _getUserDbId();
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('wishlist').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> removeFromWishlist(int productId) async {
    final userId = await _getUserDbId();
    if (userId == null) return;
    await _supabase
        .from('wishlist')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<void> toggleWishlist(int productId) async {
    if (await isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  // ── Orders ───────────────────────────────────────────────────────────────
  Future<List<AppOrder>> getOrders() async {
    final userId = await _getUserDbId();
    if (userId == null) return [];
    final res = await _supabase
        .from('orders')
        .select('*, order_items(*, products(name, image_url))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((j) => AppOrder.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Reviews ──────────────────────────────────────────────────────────────
  Future<List<Review>> getMyReviews() async {
    final userId = await _getUserDbId();
    if (userId == null) return [];
    final res = await _supabase
        .from('reviews')
        .select('*, products(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((j) => Review.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final userId = await _getUserDbId();
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('reviews').upsert({
      'user_id': userId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> deleteReview(int reviewId) async {
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }

  // ── Stats (orders + wishlist + reviews count) ────────────────────────────
  Future<Map<String, int>> getProfileStats() async {
    final userId = await _getUserDbId();
    if (userId == null) return {'orders': 0, 'wishlist': 0, 'reviews': 0};
    final results = await Future.wait([
      _supabase.from('orders').select('id').eq('user_id', userId),
      _supabase.from('wishlist').select('id').eq('user_id', userId),
      _supabase.from('reviews').select('id').eq('user_id', userId),
    ]);
    return {
      'orders': (results[0] as List).length,
      'wishlist': (results[1] as List).length,
      'reviews': (results[2] as List).length,
    };
  }
}
