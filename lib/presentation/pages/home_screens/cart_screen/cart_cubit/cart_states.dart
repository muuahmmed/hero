import '../../../../../data/models/cart_item_model.dart';

sealed class CartState {}

final class CartInitial extends CartState {}

final class CartLoading extends CartState {}

final class CartLoaded extends CartState {
  final List<CartItem> items;

  CartLoaded({required this.items});
}

final class CartError extends CartState {
  final String error;

  CartError({required this.error});
}