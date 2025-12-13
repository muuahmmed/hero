import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/presentation/pages/auth/cubit/auth_config_cubit.dart';

class AuthSettingsScreen extends StatelessWidget {
  const AuthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Configuration')),
      body: BlocBuilder<AuthConfigCubit, AuthConfigState>(
        builder: (context, state) {
          if (state is AuthConfigLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 🔹 Password Policy
              _buildPasswordPolicyCard(context),
              const SizedBox(height: 16),
              // 🔹 OAuth Providers
              _buildOAuthCard(context),
              const SizedBox(height: 16),
              // 🔹 Rate Limits
              _buildRateLimitCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordPolicyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Minimum Length'),
                      Slider(
                        value: 8,
                        min: 6,
                        max: 20,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Require Numbers'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthConfigCubit>().updatePasswordPolicy(
                  minLength: 8,
                  requireNumbers: true,
                  requireSymbols: false,
                );
              },
              child: const Text('Update Policy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOAuthCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OAuth Providers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.g_mobiledata, color: Colors.red),
              title: const Text('Google'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  if (value) {
                    _showGoogleAuthDialog(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateLimitCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate Limits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Slider(
              value: 5,
              min: 1,
              max: 10,
              divisions: 9,
              label: '5 attempts',
              onChanged: (value) {},
            ),
            const Text('Max login attempts per 15 minutes'),
          ],
        ),
      ),
    );
  }

  void _showGoogleAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Google OAuth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Client ID')),
            const SizedBox(height: 10),
            TextField(decoration: const InputDecoration(labelText: 'Client Secret')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthConfigCubit>().addGoogleAuth('client-id', 'client-secret');
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}