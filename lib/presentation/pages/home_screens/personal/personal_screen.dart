import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hero/data/models/profile_models.dart';
import 'package:hero/data/models/user_model.dart' as models;
import 'package:hero/presentation/pages/auth/cubit/auth_cubit.dart';
import 'package:hero/presentation/pages/auth/cubit/auth_states.dart';
import 'package:hero/presentation/pages/home_screens/personal/profile_cubit/cubit.dart';
import 'package:hero/presentation/pages/home_screens/personal/profile_cubit/states.dart';

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

class _PersonalBody extends StatefulWidget {
  const _PersonalBody();

  @override
  State<_PersonalBody> createState() => _PersonalBodyState();
}

class _PersonalBodyState extends State<_PersonalBody> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildProfile(BuildContext context, models.AppUser user) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final stats = profileState is ProfileLoaded
            ? profileState.stats
            : <String, int>{'orders': 0, 'wishlist': 0, 'reviews': 0};

        return RefreshIndicator(
          onRefresh: () => context.read<ProfileCubit>().loadProfile(),
          child: CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
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
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showEditProfile(context, user),
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
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats (tappable) ──────────────────────────────
                      Row(
                        children: [
                          _StatCard(
                            value: '${stats['orders'] ?? 0}',
                            label: 'Orders',
                            icon: Icons.shopping_bag_outlined,
                            color: const Color(0xFF3B82F6),
                            onTap: () => _showOrders(context, profileState),
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
                      ),

                      const SizedBox(height: 24),

                      // ── Account Info ──────────────────────────────────
                      const _SectionTitle(title: 'Account Information'),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _ProfileTile(
                            icon: Icons.person_outline,
                            title: 'Full Name',
                            value: user.fullName,
                          ),
                          const Divider(height: 1),
                          _ProfileTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: user.email,
                          ),
                          const Divider(height: 1),
                          _ProfileTile(
                            icon: Icons.phone_outlined,
                            title: 'Phone',
                            value: user.phone?.isNotEmpty == true
                                ? user.phone!
                                : 'Not provided',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── My Activity ───────────────────────────────────
                      const _SectionTitle(title: 'My Activity'),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _ActionTile(
                            icon: Icons.receipt_long_outlined,
                            title: 'Order History',
                            subtitle: 'View all your past orders',
                            color: Colors.teal,
                            onTap: () => _showOrders(context, profileState),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.favorite_border,
                            title: 'My Wishlist',
                            subtitle: "Products you've saved",
                            color: Colors.red,
                            onTap: () => _showWishlist(context, profileState),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.star_border,
                            title: 'My Reviews',
                            subtitle: "Reviews you've written",
                            color: Colors.amber,
                            onTap: () => _showMyReviews(context, profileState),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Settings ──────────────────────────────────────
                      const _SectionTitle(title: 'Settings'),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _ActionTile(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Update your name & phone',
                            color: const Color(0xFF3B82F6),
                            onTap: () => _showEditProfile(context, user),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            color: Colors.orange,
                            onTap: () => _showChangePassword(context),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Manage your alerts',
                            color: Colors.amber,
                            onTap: () =>
                                _snack(context, 'Notifications coming soon!'),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.location_on_outlined,
                            title: 'Saved Addresses',
                            subtitle: 'Manage delivery addresses',
                            color: Colors.indigo,
                            onTap: () =>
                                _snack(context, 'Saved Addresses coming soon!'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Support ───────────────────────────────────────
                      const _SectionTitle(title: 'Support'),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _ActionTile(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'FAQs and support',
                            color: Colors.green,
                            onTap: () =>
                                _snack(context, 'Help Center coming soon!'),
                          ),
                          const Divider(height: 1),
                          _ActionTile(
                            icon: Icons.chat_bubble_outline,
                            title: 'Contact Us',
                            subtitle: 'Chat with our support team',
                            color: Colors.cyan,
                            onTap: () =>
                                _snack(context, 'Contact Us coming soon!'),
                          ),
                          const Divider(height: 1),
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
                              children: [
                                const Text(
                                  'Hero Fitness is a premium supplement and fitness accessories store.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Sign Out button ───────────────────────────────
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
                      const SizedBox(height: 24),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  // ── Orders bottom sheet ────────────────────────────────────────────────────
  void _showOrders(BuildContext context, ProfileState state) {
    final orders = state is ProfileLoaded ? state.orders : <AppOrder>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        title: 'Order History',
        child: orders.isEmpty
            ? const _Empty(icon: Icons.receipt_long, label: 'No orders yet')
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => _OrderTile(order: orders[i]),
              ),
      ),
    );
  }

  // ── Wishlist bottom sheet ──────────────────────────────────────────────────
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
                      label: 'No items in wishlist',
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
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

  // ── Reviews bottom sheet ───────────────────────────────────────────────────
  void _showMyReviews(BuildContext context, ProfileState state) {
    final cubit = context.read<ProfileCubit>();
    final reviews = state is ProfileLoaded ? state.reviews : <Review>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _Sheet(
          title: 'My Reviews',
          child: reviews.isEmpty
              ? const _Empty(icon: Icons.star_border, label: 'No reviews yet')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ReviewTile(
                    review: reviews[i],
                    onDelete: () => context.read<ProfileCubit>().deleteReview(
                      reviews[i].id,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Edit Profile bottom sheet ──────────────────────────────────────────────
  void _showEditProfile(BuildContext context, models.AppUser user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final cubit = context.read<ProfileCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _Sheet(
          title: 'Edit Profile',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await cubit.updateProfile(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Profile updated!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change Password bottom sheet ───────────────────────────────────────────
  void _showChangePassword(BuildContext context) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final cubit = context.read<ProfileCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _Sheet(
          title: 'Change Password',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PwField(ctrl: newCtrl, label: 'New Password'),
              const SizedBox(height: 16),
              _PwField(ctrl: confirmCtrl, label: 'Confirm New Password'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (newCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimum 6 characters'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      await cubit.changePassword(newCtrl.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Password changed!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    );
  }

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
}

// ── List Tile Widgets ─────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final AppOrder order;
  const _OrderTile({required this.order});

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.receipt_long, color: Colors.blue, size: 22),
      ),
      title: Text(
        'Order #${order.id}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        order.createdAt != null
            ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}'
            : 'N/A',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${order.total?.toStringAsFixed(0) ?? '0'} EGP',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status ?? 'pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onRemove;
  const _WishlistTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.productImage != null
            ? CachedNetworkImage(
                imageUrl: item.productImage!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _imgPlaceholder(),
              )
            : _imgPlaceholder(),
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
        tooltip: 'Remove from wishlist',
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 50,
    height: 50,
    color: Colors.grey[100],
    child: const Icon(Icons.fitness_center, color: Colors.grey),
  );
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final VoidCallback onDelete;
  const _ReviewTile({required this.review, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        tooltip: 'Delete review',
      ),
    );
  }
}

// ── Reusable UI ───────────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
      padding: const EdgeInsets.symmetric(vertical: 32),
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
  const _PwField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
  final String title;
  final String value;
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
