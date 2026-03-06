import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:hero/presentation/pages/home_screens/personal/profile_cubit/states.dart';
import '../../../../../data/models/profile_models.dart';
import '../../../../../data/services/profile_service.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _service = ProfileService();

  ProfileCubit() : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final results = await Future.wait([
        _service.getProfile(),
        _service.getWishlist(),
        _service.getOrders(),
        _service.getMyReviews(),
        _service.getProfileStats(),
      ]);
      emit(
        ProfileLoaded(
          profile: results[0] as UserProfile?,
          wishlist: results[1] as List<WishlistItem>,
          orders: results[2] as List<AppOrder>,
          reviews: results[3] as List<Review>,
          stats: results[4] as Map<String, int>,
        ),
      );
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final s = state;
    if (s is! ProfileLoaded) return;
    emit(s.copyWith(isUpdating: true));
    try {
      await _service.updateProfile(name: name, phone: phone);
      // Refresh profile from DB so UI shows updated values immediately
      final updated = await _service.getProfile();
      emit(s.copyWith(isUpdating: false, profile: updated));
    } catch (e) {
      emit(s.copyWith(isUpdating: false));
      rethrow;
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    final s = state;
    if (s is! ProfileLoaded) return;
    emit(s.copyWith(isUploadingAvatar: true));
    try {
      final url = await _service.uploadAvatar(imageFile);
      final updated = s.profile?.copyWith(avatarUrl: url);
      emit(s.copyWith(isUploadingAvatar: false, profile: updated));
    } catch (e) {
      emit(s.copyWith(isUploadingAvatar: false));
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _service.changePassword(newPassword);
  }

  Future<void> toggleWishlist(int productId) async {
    await _service.toggleWishlist(productId);
    final s = state;
    if (s is! ProfileLoaded) return;
    final wishlist = await _service.getWishlist();
    final stats = await _service.getProfileStats();
    emit(s.copyWith(wishlist: wishlist, stats: stats));
  }

  Future<void> deleteReview(int reviewId) async {
    await _service.deleteReview(reviewId);
    final s = state;
    if (s is! ProfileLoaded) return;
    final reviews = await _service.getMyReviews();
    final stats = await _service.getProfileStats();
    emit(s.copyWith(reviews: reviews, stats: stats));
  }
}
