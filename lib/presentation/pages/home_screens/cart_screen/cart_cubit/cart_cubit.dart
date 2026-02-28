import 'package:bloc/bloc.dart';
import 'package:hero/data/models/cart_item_model.dart';
import 'cart_states.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());

  void addToCart(CartItem item) {
    final state = this.state;
    List<CartItem> currentItems = [];

    if (state is CartLoaded) {
      currentItems = List<CartItem>.from(state.items);
      final existingIndex = currentItems.indexWhere(
            (element) => element.productId == item.productId,
      );

      if (existingIndex >= 0) {
        currentItems[existingIndex] = currentItems[existingIndex].copyWith(
          quantity: currentItems[existingIndex].quantity + item.quantity,
        );
      } else {
        currentItems.add(item);
      }
    } else {
      currentItems = [item];
    }

    emit(CartLoaded(items: currentItems));
  }

  void removeFromCart(int productId) {
    final state = this.state;
    if (state is CartLoaded) {
      final updatedItems = state.items
          .where((item) => item.productId != productId)
          .toList();
      emit(CartLoaded(items: updatedItems));
    }
  }

  void updateQuantity(int productId, int quantity) {
    final state = this.state;
    if (state is CartLoaded) {
      if (quantity <= 0) {
        removeFromCart(productId);
        return;
      }
      final updatedItems = state.items.map((item) {
        if (item.productId == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      emit(CartLoaded(items: updatedItems));
    }
  }

  void clearCart() {
    emit(CartLoaded(items: []));
  }

  double getTotal() {
    final state = this.state;
    if (state is CartLoaded) {
      return state.items.fold(0, (total, item) {
        return total + (item.unitPrice * item.quantity);
      });
    }
    return 0;
  }

  int getItemCount() {
    final state = this.state;
    if (state is CartLoaded) {
      return state.items.fold(0, (count, item) => count + item.quantity);
    }
    return 0;
  }

  bool isInCart(int productId) {
    final state = this.state;
    if (state is CartLoaded) {
      return state.items.any((item) => item.productId == productId);
    }
    return false;
  }
}
