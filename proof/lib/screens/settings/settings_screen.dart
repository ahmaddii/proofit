import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _changePin() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Old PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.changePin(
                oldPinController.text,
                newPinController.text,
              );
              if (context.mounted) {
                Navigator.pop(context, success);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN changed successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure? This will permanently delete your account and all your proofs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AuthProvider>().deleteAccount();
      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete account'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userEmail = authProvider.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // User info
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Settings options
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePin,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _signOut,
          ),
          const Divider(),

          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.errorColor),
            title: Text(
              'Delete Account',
              style: TextStyle(color: AppColors.errorColor),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _deleteAccount,
          ),

          const SizedBox(height: 32),

          // App info
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Text(
              'ProofIt v1.0.0\n© 2024',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}