import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hero/core/utils/constants.dart';
import 'package:hero/data/models/profile_models.dart';
import 'package:hero/data/models/user_model.dart' as models;
import 'package:hero/presentation/pages/auth/cubit/auth_cubit.dart';
import 'package:hero/presentation/pages/auth/cubit/auth_states.dart';
import 'package:hero/presentation/pages/home_screens/personal/profile_cubit/cubit.dart';
import 'package:hero/presentation/pages/home_screens/personal/profile_cubit/states.dart';
import 'package:image_picker/image_picker.dart';

import '../order_history/order_history_screen.dart';

class PersonalScreen extends StatelessWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: const _PersonalBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PersonalBody extends StatefulWidget {
  const _PersonalBody();

  @override
  State<_PersonalBody> createState() => _PersonalBodyState();
}

class _PersonalBodyState extends State<_PersonalBody> {
  bool _isLoggingOut = false;

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoggingOut = true);
    try {
      await context.read<AuthCubit>().logout();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) context.go('/login');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  // ── Avatar picker ─────────────────────────────────────────────────────────
  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;
    try {
      await context.read<ProfileCubit>().uploadAvatar(File(picked.path));
      if (mounted) _snack(context, '✅ Avatar updated!', Colors.green);
    } catch (e) {
      if (mounted) _snack(context, 'Upload failed: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated || authState is AuthRegistered) {
            final user = (authState as dynamic).user as models.AppUser;
            return _buildProfile(context, user);
          }
          return _buildNotLoggedIn(context);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main profile body
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProfile(BuildContext context, models.AppUser authUser) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        // Use live DB profile if loaded, otherwise fall back to auth user
        final profile = profileState is ProfileLoaded
            ? profileState.profile
            : null;

        final displayName = profile?.name.isNotEmpty == true
            ? profile!.name
            : authUser.fullName;
        final displayEmail = profile?.email ?? authUser.email;
        final displayPhone = profile?.phone;
        final avatarUrl = profile?.avatarUrl ?? authUser.avatarUrl;
        final memberSince = profile?.createdAt;

        final stats = profileState is ProfileLoaded
            ? profileState.stats
            : <String, int>{'orders': 0, 'wishlist': 0, 'reviews': 0};

        final isUploadingAvatar =
            profileState is ProfileLoaded && profileState.isUploadingAvatar;

        return RefreshIndicator(
          color: const Color(0xFF3B82F6),
          onRefresh: () => context.read<ProfileCubit>().loadProfile(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Collapsible header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout),
                    onPressed: _handleLogout,
                    tooltip: 'Sign Out',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // ── Avatar with edit overlay ──────────────────
                          GestureDetector(
                            onTap: () => _pickAvatar(context),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: isUploadingAvatar
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF3B82F6),
                                            ),
                                          )
                                        : avatarUrl != null &&
                                              avatarUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: avatarUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                            errorWidget: (_, __, ___) =>
                                                _defaultAvatar(),
                                          )
                                        : _defaultAvatar(),
                                  ),
                                ),
                                // Camera badge
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                          if (memberSince != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Member since ${_formatMonth(memberSince)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats ───────────────────────────────────────────
                      _buildStats(context, stats, profileState),

                      const SizedBox(height: 24),

                      // ── Account Info ────────────────────────────────────
                      const _SectionTitle(title: 'Account Information'),
                      const SizedBox(height: 12),
                      _buildAccountInfo(
                        context,
                        displayName,
                        displayEmail,
                        displayPhone,
                      ),

                      const SizedBox(height: 24),

                      // ── My Activity ─────────────────────────────────────
                      const _SectionTitle(title: 'My Activity'),
                      const SizedBox(height: 12),
                      _buildActivity(context, profileState),

                      const SizedBox(height: 24),

                      // ── Settings ────────────────────────────────────────
                      const _SectionTitle(title: 'Settings'),
                      const SizedBox(height: 12),
                      _buildSettings(
                        context,
                        authUser,
                        displayName,
                        displayPhone,
                      ),

                      const SizedBox(height: 24),

                      // ── Support ─────────────────────────────────────────
                      const _SectionTitle(title: 'Support'),
                      const SizedBox(height: 12),
                      _buildSupport(context),

                      const SizedBox(height: 32),

                      // ── Sign Out ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────

  Widget _buildStats(
    BuildContext context,
    Map<String, int> stats,
    ProfileState profileState,
  ) {
    return Row(
      children: [
        _StatCard(
          value: '${stats['orders'] ?? 0}',
          label: 'Orders',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF3B82F6),
          onTap: () => navigateTo(context, const OrderHistoryScreen()),
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${stats['wishlist'] ?? 0}',
          label: 'Wishlist',
          icon: Icons.favorite_border,
          color: Colors.red,
          onTap: () => _showWishlist(context, profileState),
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${stats['reviews'] ?? 0}',
          label: 'Reviews',
          icon: Icons.star_border,
          color: Colors.amber,
          onTap: () => _showMyReviews(context, profileState),
        ),
      ],
    );
  }

  // ─── Account info card ────────────────────────────────────────────────────

  Widget _buildAccountInfo(
    BuildContext context,
    String name,
    String email,
    String? phone,
  ) {
    return _ProfileCard(
      children: [
        _ProfileTile(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF3B82F6),
          title: 'Full Name',
          value: name,
        ),
        const Divider(height: 1, indent: 68),
        _ProfileTile(
          icon: Icons.email_outlined,
          iconColor: Colors.purple,
          title: 'Email',
          value: email,
        ),
        const Divider(height: 1, indent: 68),
        _ProfileTile(
          icon: Icons.phone_outlined,
          iconColor: Colors.green,
          title: 'Phone',
          value: phone != null && phone.isNotEmpty
              ? phone
              : 'Not set — tap Edit Profile',
          valueColor: phone != null && phone.isNotEmpty
              ? null
              : Colors.grey[400],
        ),
      ],
    );
  }

  // ─── Activity card ────────────────────────────────────────────────────────

  Widget _buildActivity(BuildContext context, ProfileState profileState) {
    final orderCount = profileState is ProfileLoaded
        ? profileState.stats['orders'] ?? 0
        : 0;
    final wishlistCount = profileState is ProfileLoaded
        ? profileState.stats['wishlist'] ?? 0
        : 0;
    final reviewCount = profileState is ProfileLoaded
        ? profileState.stats['reviews'] ?? 0
        : 0;

    return _ProfileCard(
      children: [
        _ActionTile(
          icon: Icons.receipt_long_outlined,
          title: 'Order History',
          subtitle: orderCount > 0
              ? '$orderCount order${orderCount != 1 ? 's' : ''} placed'
              : 'No orders yet',
          color: Colors.teal,
          onTap: () => navigateTo(context, const OrderHistoryScreen()),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.favorite_border,
          title: 'My Wishlist',
          subtitle: wishlistCount > 0
              ? '$wishlistCount saved item${wishlistCount != 1 ? 's' : ''}'
              : 'No saved items',
          color: Colors.red,
          onTap: () => _showWishlist(context, profileState),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.star_border,
          title: 'My Reviews',
          subtitle: reviewCount > 0
              ? '$reviewCount review${reviewCount != 1 ? 's' : ''} written'
              : 'No reviews yet',
          color: Colors.amber,
          onTap: () => _showMyReviews(context, profileState),
        ),
      ],
    );
  }

  // ─── Settings card ────────────────────────────────────────────────────────

  Widget _buildSettings(
    BuildContext context,
    models.AppUser authUser,
    String displayName,
    String? displayPhone,
  ) {
    return _ProfileCard(
      children: [
        _ActionTile(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          subtitle: 'Update your name & phone',
          color: const Color(0xFF3B82F6),
          onTap: () => _showEditProfile(context, displayName, displayPhone),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your password',
          color: Colors.orange,
          onTap: () => _showChangePassword(context),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.photo_camera_outlined,
          title: 'Update Profile Photo',
          subtitle: 'Choose from your gallery',
          color: Colors.indigo,
          onTap: () => _pickAvatar(context),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage your alerts',
          color: Colors.amber,
          onTap: () => _snack(context, 'Notifications coming soon!'),
        ),
      ],
    );
  }

  // ─── Support card ─────────────────────────────────────────────────────────

  Widget _buildSupport(BuildContext context) {
    return _ProfileCard(
      children: [
        _ActionTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'FAQs and support',
          color: Colors.green,
          onTap: () => _snack(context, 'Help Center coming soon!'),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.chat_bubble_outline,
          title: 'Contact Us',
          subtitle: 'Chat with our support team',
          color: Colors.cyan,
          onTap: () => _snack(context, 'Contact Us coming soon!'),
        ),
        const Divider(height: 1, indent: 68),
        _ActionTile(
          icon: Icons.info_outline,
          title: 'About Hero Fitness',
          subtitle: 'Version 1.0.0',
          color: Colors.grey,
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Hero Fitness',
            applicationVersion: '1.0.0',
            applicationIcon: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 32,
              ),
            ),
            children: const [
              Text(
                'Hero Fitness is a premium supplement and fitness accessories store.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Not logged in ────────────────────────────────────────────────────────

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not Signed In',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Please sign in to view your profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom sheets
  // ─────────────────────────────────────────────────────────────────────────

  void _showWishlist(BuildContext context, ProfileState state) {
    final cubit = context.read<ProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (ctx, ps) {
            final list = ps is ProfileLoaded ? ps.wishlist : <WishlistItem>[];
            return _Sheet(
              title: 'My Wishlist',
              child: list.isEmpty
                  ? const _Empty(
                      icon: Icons.favorite_border,
                      label: 'Your wishlist is empty',
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) => _WishlistTile(
                        item: list[i],
                        onRemove: () => ctx.read<ProfileCubit>().toggleWishlist(
                          list[i].productId,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  void _showMyReviews(BuildContext context, ProfileState state) {
    final cubit = context.read<ProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (ctx, ps) {
            final reviews = ps is ProfileLoaded ? ps.reviews : <Review>[];
            return _Sheet(
              title: 'My Reviews',
              child: reviews.isEmpty
                  ? const _Empty(
                      icon: Icons.star_border,
                      label: 'No reviews yet',
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) => _ReviewTile(
                        review: reviews[i],
                        onDelete: () => ctx.read<ProfileCubit>().deleteReview(
                          reviews[i].id,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  void _showEditProfile(
    BuildContext context,
    String currentName,
    String? currentPhone,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');
    final cubit = context.read<ProfileCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: cubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _Sheet(
            title: 'Edit Profile',
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (ctx, ps) {
                final isUpdating = ps is ProfileLoaded && ps.isUpdating;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF3B82F6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUpdating
                            ? null
                            : () async {
                                try {
                                  await cubit.updateProfile(
                                    name: nameCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim(),
                                  );
                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                    _snack(
                                      context,
                                      '✅ Profile updated!',
                                      Colors.green,
                                    );
                                  }
                                } catch (e) {
                                  if (sheetCtx.mounted) {
                                    _snack(context, 'Error: $e', Colors.red);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final cubit = context.read<ProfileCubit>();
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _Sheet(
            title: 'Change Password',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PwField(
                  ctrl: newCtrl,
                  label: 'New Password',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setModalState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),
                _PwField(
                  ctrl: confirmCtrl,
                  label: 'Confirm Password',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setModalState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        _snack(context, 'Passwords do not match', Colors.red);
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        _snack(context, 'Minimum 6 characters', Colors.red);
                        return;
                      }
                      try {
                        await cubit.changePassword(newCtrl.text);
                        if (sheetCtx.mounted) {
                          Navigator.pop(sheetCtx);
                          _snack(context, '✅ Password changed!', Colors.green);
                        }
                      } catch (e) {
                        if (sheetCtx.mounted) {
                          _snack(context, 'Error: $e', Colors.red);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Password',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _snack(
    BuildContext context,
    String msg, [
    Color color = const Color(0xFF1E293B),
  ]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Icon(Icons.person, size: 48, color: Color(0xFF3B82F6)),
    );
  }

  String _formatMonth(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wishlist & Review tiles
// ─────────────────────────────────────────────────────────────────────────────

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onRemove;
  const _WishlistTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 52,
          height: 52,
          color: Colors.grey[100],
          child: item.productImage != null
              ? CachedNetworkImage(
                  imageUrl: item.productImage!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.fitness_center, color: Colors.grey),
                )
              : const Icon(Icons.fitness_center, color: Colors.grey),
        ),
      ),
      title: Text(
        item.productName ?? 'Product',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${item.productPrice?.toStringAsFixed(0) ?? '0'} EGP',
        style: const TextStyle(
          color: Color(0xFF3B82F6),
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
        onPressed: onRemove,
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final VoidCallback onDelete;
  const _ReviewTile({required this.review, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.star, color: Colors.amber, size: 22),
      ),
      title: Text(
        review.productName ?? 'Product',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber,
              ),
            ),
          ),
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(
              review.comment!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: Colors.red[300]),
        onPressed: onDelete,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable UI components
// ─────────────────────────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Empty({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PwField({
    required this.ctrl,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color? valueColor;
  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: valueColor ?? Colors.black87,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
