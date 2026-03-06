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
  final UserProfile? profile;       // live data from DB
  final List<WishlistItem> wishlist;
  final List<AppOrder> orders;
  final List<Review> reviews;
  final Map<String, int> stats;
  final bool isUpdating;
  final bool isUploadingAvatar;

  ProfileLoaded({
    this.profile,
    this.wishlist = const [],
    this.orders = const [],
    this.reviews = const [],
    this.stats = const {'orders': 0, 'wishlist': 0, 'reviews': 0},
    this.isUpdating = false,
    this.isUploadingAvatar = false,
  });

  ProfileLoaded copyWith({
    UserProfile? profile,
    List<WishlistItem>? wishlist,
    List<AppOrder>? orders,
    List<Review>? reviews,
    Map<String, int>? stats,
    bool? isUpdating,
    bool? isUploadingAvatar,
  }) =>
      ProfileLoaded(
        profile: profile ?? this.profile,
        wishlist: wishlist ?? this.wishlist,
        orders: orders ?? this.orders,
        reviews: reviews ?? this.reviews,
        stats: stats ?? this.stats,
        isUpdating: isUpdating ?? this.isUpdating,
        isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      );

  @override
  List<Object?> get props =>
      [profile, wishlist, orders, reviews, stats, isUpdating, isUploadingAvatar];
}