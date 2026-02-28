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
                  borderRadius: BorderRadius.circular(10)),
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
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go('/login');
    } catch (e) {
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
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Avatar
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
                      fontSize: 14,
                    ),
                  ),
                ],
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
                    strokeWidth: 2, color: Colors.white),
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
                // Account Info Section
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

                // Settings Section
                _SectionTitle(title: 'Settings'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _ActionTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      color: Colors.orange,
                      onTap: () => _showComingSoon(context, 'Notifications'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      color: const Color(0xFF3B82F6),
                      onTap: () => _showComingSoon(context, 'Change Password'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.language,
                      title: 'Language',
                      color: Colors.green,
                      trailing: const Text('Arabic / English',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      onTap: () => _showComingSoon(context, 'Language'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Orders Section
                _SectionTitle(title: 'My Orders'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _ActionTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Track My Orders',
                      color: Colors.purple,
                      onTap: () => _showComingSoon(context, 'Order Tracking'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.history,
                      title: 'Order History',
                      color: Colors.teal,
                      onTap: () => _showComingSoon(context, 'Order History'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.favorite_border,
                      title: 'Wishlist',
                      color: Colors.red,
                      onTap: () => _showComingSoon(context, 'Wishlist'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Support Section
                _SectionTitle(title: 'Support'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _ActionTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      color: Colors.indigo,
                      onTap: () => _showComingSoon(context, 'Help Center'),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.info_outline,
                      title: 'About Hero Fitness',
                      color: Colors.grey,
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              'Please sign in to view your profile and manage your account',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
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
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      title: Text(title,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(
        value,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style:
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
