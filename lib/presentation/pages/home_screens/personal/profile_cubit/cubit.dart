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
        _service.getWishlist(),
        _service.getOrders(),
        _service.getMyReviews(),
        _service.getProfileStats(),
      ]);
      emit(ProfileLoaded(
        wishlist: results[0] as List<WishlistItem>,
        orders: results[1] as List<AppOrder>,
        reviews: results[2] as List<Review>,
        stats: results[3] as Map<String, int>,
      ));
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
      emit(s.copyWith(isUpdating: false));
    } catch (e) {
      emit(s.copyWith(isUpdating: false));
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
