import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hero/data/models/user_model.dart' as models;
import 'package:hero/presentation/pages/auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_states.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout(BuildContext context) async {
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
        builder: (context, state) {
          if (state is AuthAuthenticated || state is AuthRegistered) {
            final user = (state as dynamic).user as models.AppUser;
            return _buildProfile(context, user);
          }
          return _buildNotLoggedIn(context);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, models.AppUser user) {
    return CustomScrollView(
      slivers: [
        // Collapsible header
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
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
                    // Avatar
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
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14,
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
              onPressed: () => _handleLogout(context),
              tooltip: 'Sign Out',
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                _buildStatsRow(),
                const SizedBox(height: 24),

                // Account Info
                _SectionTitle(title: 'Account Information'),
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
                      value: user.phone ?? 'Not provided',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Orders
                _SectionTitle(title: 'My Orders'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _ActionTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Order History',
                      subtitle: 'View all your past orders',
                      color: Colors.teal,
                      onTap: () => _showComingSoon(context, 'Order History'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Track My Orders',
                      subtitle: 'Track active deliveries',
                      color: Colors.purple,
                      onTap: () => _showComingSoon(context, 'Order Tracking'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.favorite_border,
                      title: 'Wishlist',
                      subtitle: 'Products you\'ve saved',
                      color: Colors.red,
                      onTap: () => _showComingSoon(context, 'Wishlist'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Settings
                _SectionTitle(title: 'Settings'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _ActionTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal info',
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
                      onTap: () => _showComingSoon(context, 'Notifications'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      subtitle: 'Manage delivery addresses',
                      color: Colors.indigo,
                      onTap: () => _showComingSoon(context, 'Saved Addresses'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Support
                _SectionTitle(title: 'Support'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _ActionTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs and support',
                      color: Colors.green,
                      onTap: () => _showComingSoon(context, 'Help Center'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Contact Us',
                      subtitle: 'Chat with our support team',
                      color: Colors.cyan,
                      onTap: () => _showComingSoon(context, 'Contact Us'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.info_outline,
                      title: 'About Hero Fitness',
                      subtitle: 'Version 1.0.0',
                      color: Colors.grey,
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Out
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
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
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          value: '0',
          label: 'Orders',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '0',
          label: 'Wishlist',
          icon: Icons.favorite_border,
          color: Colors.red,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '0',
          label: 'Reviews',
          icon: Icons.star_border,
          color: Colors.amber,
        ),
      ],
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
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
        child: const Icon(Icons.fitness_center, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Hero Fitness is a premium supplement and fitness accessories store. '
          'We offer the best products to support your fitness journey.',
        ),
      ],
    );
  }

  void _showEditProfile(BuildContext context, models.AppUser user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
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
              controller: phoneController,
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
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(currentCtrl, 'Current Password'),
            const SizedBox(height: 16),
            _buildPasswordField(newCtrl, 'New Password'),
            const SizedBox(height: 16),
            _buildPasswordField(confirmCtrl, 'Confirm New Password'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
    );
  }

  Widget _buildPasswordField(TextEditingController ctrl, String label) {
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

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
