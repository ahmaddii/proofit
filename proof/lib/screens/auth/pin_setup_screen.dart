import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../home/home_dashboard.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (_pinController.text.length < 4 || _pinController.text.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN must be 4-6 digits'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.setupPin(_pinController.text);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to setup PIN'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PIN'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primaryColor,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Secure Your Proofs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Create a 4-6 digit PIN to protect your evidence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // PIN field
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Enter PIN (4-6 digits)',
                  prefixIcon: const Icon(Icons.pin),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  counterText: '',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Confirm PIN field
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  counterText: '',
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Setup button
              ElevatedButton(
                onPressed: _isLoading ? null : _setupPin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Setup PIN'),
              ),
              
              const SizedBox(height: 16),
              
              // Skip button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeDashboard()),
                  );
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}