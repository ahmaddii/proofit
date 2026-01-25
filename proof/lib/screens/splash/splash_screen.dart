import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../home/home_dashboard.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/preferences_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0), // Start from top
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));

    _controller.forward();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // Check onboarding
    if (!PreferencesService.isOnboardingCompleted()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // Check auth session
    final authProvider = context.read<AuthProvider>();
    // We can check if session exists via provider or Supabase instance directly
    // Ideally AuthProvider should have initialized state.
    // However, AuthWrapper logic in main.dart handles the stream.
    // Since we are replacing AuthWrapper's initial view with this Splash,
    // we need to decide where to go.

    // Better approach: Let AuthWrapper handle the stream, but show Splash
    // until we decide to switch.
    // BUT user wants Splash -> Then Onboarding/Login.

    // Checking session:
    if (authProvider.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF7F).withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF7F).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                // Use the logo from assets
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    'assets/animations/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.shield_outlined,
                        size: 60,
                        color: Color(0xFF00FF7F),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'ProofIt',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 64),

            // Loader
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF00FF7F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
