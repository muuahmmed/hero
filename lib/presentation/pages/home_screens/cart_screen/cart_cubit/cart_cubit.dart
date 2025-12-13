import 'package:bloc/bloc.dart';
import 'package:hero/data/models/cart_item_model.dart';
import 'cart_states.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());

  void addToCart(CartItem item) {
    final state = this.state;
    if (state is CartLoaded) {
      final updatedItems = List<CartItem>.from(state.items);

      final existingIndex = updatedItems.indexWhere(
        (element) => element.productId == item.productId,
      );

      if (existingIndex >= 0) {
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: updatedItems[existingIndex].quantity + item.quantity,
        );
      } else {
        updatedItems.add(item);
      }

      emit(CartLoaded(items: updatedItems));
    } else {
      emit(CartLoaded(items: [item]));
    }
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
}
