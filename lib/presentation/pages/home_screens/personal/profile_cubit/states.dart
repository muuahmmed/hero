import 'package:equatable/equatable.dart';
import '../../../../../data/models/profile_models.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileLoaded extends ProfileState {
  final List<WishlistItem> wishlist;
  final List<AppOrder> orders;
  final List<Review> reviews;
  final Map<String, int> stats;
  final bool isUpdating;

  ProfileLoaded({
    this.wishlist = const [],
    this.orders = const [],
    this.reviews = const [],
    this.stats = const {'orders': 0, 'wishlist': 0, 'reviews': 0},
    this.isUpdating = false,
  });

  ProfileLoaded copyWith({
    List<WishlistItem>? wishlist,
    List<AppOrder>? orders,
    List<Review>? reviews,
    Map<String, int>? stats,
    bool? isUpdating,
  }) =>
      ProfileLoaded(
        wishlist: wishlist ?? this.wishlist,
        orders: orders ?? this.orders,
        reviews: reviews ?? this.reviews,
        stats: stats ?? this.stats,
        isUpdating: isUpdating ?? this.isUpdating,
      );

  @override
  List<Object?> get props => [wishlist, orders, reviews, stats, isUpdating];
}