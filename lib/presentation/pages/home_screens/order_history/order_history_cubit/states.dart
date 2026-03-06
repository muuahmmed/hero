import 'package:hero/data/models/profile_models.dart';

abstract class OrderHistoryState {}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<AppOrder> orders;
  final String? selectedStatus; // null = all

  OrderHistoryLoaded({required this.orders, this.selectedStatus});

  List<AppOrder> get filtered {
    if (selectedStatus == null) return orders;
    return orders.where((o) => o.status == selectedStatus).toList();
  }

  OrderHistoryLoaded copyWith({
    List<AppOrder>? orders,
    String? selectedStatus,
    bool clearFilter = false,
  }) {
    return OrderHistoryLoaded(
      orders: orders ?? this.orders,
      selectedStatus: clearFilter ? null : (selectedStatus ?? this.selectedStatus),
    );
  }
}

class OrderHistoryError extends OrderHistoryState {
  final String message;
  OrderHistoryError(this.message);
}