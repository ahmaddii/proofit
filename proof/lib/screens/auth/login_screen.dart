import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/preferences_service.dart';
import 'signup_screen.dart';
import 'pin_setup_screen.dart';
import '../home/home_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  static const Color neonGreen = Color(0xFF00FF7F);

  @override
  void initState() {
    super.initState();
    _loadLastEmail();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Reduced from 1200ms
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _loadLastEmail() async {
    final lastEmail = PreferencesService.getLastEmail();
    if (lastEmail != null) {
      _emailController.text = lastEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    await PreferencesService.setLastEmail(email);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(email, _passwordController.text);

    if (!mounted) return;

    if (success) {
      final hasPinSetup = await authProvider.hasPinSetup();
      if (!hasPinSetup) {
        // New user - needs to setup PIN
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        );
      } else {
        // Existing user - go to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboard()),
        );
        // OR if using named routes:
        // Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: neonGreen),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: neonGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
              vertical: 16,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Logo Icon
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: neonGreen.withOpacity(0.6),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              size: 72,
                              color: neonGreen,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App Name
                      Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Glass Card with Form
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                          border: Border.all(
                            color: neonGreen.withOpacity(0.25),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      label: AppStrings.email,
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (v) =>
                                        v != null && v.contains('@')
                                        ? null
                                        : 'Enter a valid email',
                                  ),

                                  const SizedBox(height: 20),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    decoration: _inputDecoration(
                                      label: AppStrings.password,
                                      icon: Icons.lock_outline,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: neonGreen,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (v) => v != null && v.length >= 6
                                        ? null
                                        : 'Min 6 characters',
                                  ),

                                  const SizedBox(height: 30),

                                  // Login Button
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) {
                                      return GestureDetector(
                                        onTap: auth.isLoading
                                            ? null
                                            : _handleLogin,
                                        child: Container(
                                          height: 56,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: neonGreen,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: neonGreen.withOpacity(
                                                  0.6,
                                                ),
                                                blurRadius: 22,
                                              ),
                                            ],
                                          ),
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.black,
                                                        strokeWidth: 3,
                                                      ),
                                                )
                                              : const Text(
                                                  AppStrings.login,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Google Sign In Button
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) {
                          return GestureDetector(
                            onTap: auth.isLoading
                                ? null
                                : () async {
                                    final success = await auth
                                        .signInWithGoogle();
                                    if (!mounted) return;

                                    if (success) {
                                      final hasPinSetup = await auth
                                          .hasPinSetup();
                                      if (!mounted) return;

                                      if (!hasPinSetup) {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PinSetupScreen(),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HomeDashboard(),
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            auth.errorMessage ??
                                                'Google Sign-In failed',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/animations/google.png',
                                    height: 22,
                                    width: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: neonGreen),
                              ),
                              child: const Text(
                                AppStrings.signup,
                                style: TextStyle(
                                  color: neonGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
