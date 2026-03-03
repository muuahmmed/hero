import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:hero/data/models/cart_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_states.dart';

class CartCubit extends Cubit<CartState> {
  static const String _cartKey = 'hero_cart_items';

  CartCubit() : super(CartInitial()) {
    _loadCart(); // Load saved cart on startup
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cartKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final items = jsonList
            .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
            .toList();
        emit(CartLoaded(items: items));
        print('🛒 Cart loaded: ${items.length} items');
      } else {
        emit(CartLoaded(items: []));
      }
    } catch (e) {
      print('❌ Error loading cart: $e');
      emit(CartLoaded(items: []));
    }
  }

  Future<void> _saveCart(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, jsonEncode(jsonList));
    } catch (e) {
      print('❌ Error saving cart: $e');
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void addToCart(CartItem item) {
    final currentItems = _currentItems;
    final existingIndex =
    currentItems.indexWhere((e) => e.productId == item.productId);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      // Product already in cart — increase quantity
      updatedItems = List<CartItem>.from(currentItems);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + item.quantity,
      );
    } else {
      updatedItems = [...currentItems, item];
    }

    emit(CartLoaded(items: updatedItems));
    _saveCart(updatedItems);
  }

  void removeFromCart(int productId) {
    final updatedItems =
    _currentItems.where((item) => item.productId != productId).toList();
    emit(CartLoaded(items: updatedItems));
    _saveCart(updatedItems);
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final updatedItems = _currentItems.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    emit(CartLoaded(items: updatedItems));
    _saveCart(updatedItems);
  }

  void clearCart() {
    emit(CartLoaded(items: []));
    _saveCart([]);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<CartItem> get _currentItems {
    final s = state;
    return s is CartLoaded ? List<CartItem>.from(s.items) : [];
  }

  double getTotal() {
    return _currentItems.fold(
        0, (total, item) => total + (item.unitPrice * item.quantity));
  }

  int getItemCount() {
    return _currentItems.fold(0, (count, item) => count + item.quantity);
  }

  bool isInCart(int productId) {
    return _currentItems.any((item) => item.productId == productId);
  }
}