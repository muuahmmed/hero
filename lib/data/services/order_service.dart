import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the integer user id from the `users` table
  Future<int> _getUserDbId() async {
    final authUid = _supabase.auth.currentUser?.id;
    if (authUid == null) throw Exception('Not authenticated');
    final res = await _supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authUid)
        .single();
    return res['id'] as int;
  }

  /// Inserts a new order + all order_items into Supabase.
  /// Returns the newly created order id.
  Future<int> placeOrder({
    required List<CartItem> items,
    required double total,
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
    String? notes,
  }) async {
    final userId = await _getUserDbId();

    // 1 ── Insert order header
    final orderRow = await _supabase
        .from('orders')
        .insert({
          'user_id': userId,
          'status': 'pending',
          'total': total,
          'shipping_address': shippingAddress,
          'phone': phone,
          'payment_method': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final orderId = orderRow['id'] as int;

    // 2 ── Insert all order_items in one batch call
    final rows = items
        .map(
          (item) => {
            'order_id': orderId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'price': item.unitPrice,
          },
        )
        .toList();

    await _supabase.from('order_items').insert(rows);

    return orderId;
  }

  /// Pre-fills the user's saved phone number from the users table.
  Future<String?> getSavedPhone() async {
    try {
      final authUid = _supabase.auth.currentUser?.id;
      if (authUid == null) return null;
      final res = await _supabase
          .from('users')
          .select('phone')
          .eq('auth_user_id', authUid)
          .maybeSingle();
      return res?['phone'] as String?;
    } catch (_) {
      return null;
    }
  }
}
