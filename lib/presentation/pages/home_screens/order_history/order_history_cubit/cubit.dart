import 'package:bloc/bloc.dart';
import 'package:hero/data/services/profile_service.dart';
import 'package:hero/presentation/pages/home_screens/order_history/order_history_cubit/states.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final ProfileService _service = ProfileService();

  OrderHistoryCubit() : super(OrderHistoryInitial());

  Future<void> loadOrders() async {
    emit(OrderHistoryLoading());
    try {
      final orders = await _service.getOrders();
      emit(OrderHistoryLoaded(orders: orders));
    } catch (e) {
      emit(OrderHistoryError(e.toString()));
    }
  }

  Future<void> refresh() => loadOrders();

  void filterByStatus(String? status) {
    final s = state;
    if (s is! OrderHistoryLoaded) return;
    if (status == null) {
      emit(s.copyWith(clearFilter: true));
    } else {
      emit(OrderHistoryLoaded(orders: s.orders, selectedStatus: status));
    }
  }
}