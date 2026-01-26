import 'package:flutter/material.dart';
import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation - logo drops from top
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -3.0), // Start from way above screen
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Curves.elasticOut, // Bouncy effect
          ),
        );

    // Scale animation - logo bounces
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotate animation - slight rotation while dropping
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _rotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.elasticOut),
    );

    // Fade animation for text and other elements
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Pulse animation for continuous glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation - expands after logo lands
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    // Start animations immediately - no delay
    _startAnimations();

    // Navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 6500), _navigate);
  }

  void _startAnimations() {
    // Start logo drop immediately
    _slideController.forward();
    _scaleController.forward();
    _rotateController.forward();

    // After logo lands, show glow
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _glowController.forward();
      }
    });

    // Show text elements after logo settles
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
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
    if (authProvider.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0 * _glowAnimation.value,
                    colors: [
                      const Color(
                        0xFF00FF7F,
                      ).withOpacity(0.08 * _glowAnimation.value),
                      const Color(
                        0xFF00FF7F,
                      ).withOpacity(0.03 * _glowAnimation.value),
                      const Color(0xFF0B0B0F),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              );
            },
          ),

          // Particle effects
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_glowAnimation.value),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo dropping from top
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _scaleAnimation,
                      _rotateAnimation,
                      _glowAnimation,
                      _pulseAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer expanding glow rings
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width:
                                        180 *
                                        _glowAnimation.value *
                                        _pulseAnimation.value,
                                    height:
                                        180 *
                                        _glowAnimation.value *
                                        _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF00FF7F)
                                            .withOpacity(
                                              0.15 *
                                                  _glowAnimation.value *
                                                  (2 - _pulseAnimation.value),
                                            ),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Middle glow ring
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF00FF7F).withOpacity(
                                        0.15 *
                                            _glowAnimation.value *
                                            _pulseAnimation.value,
                                      ),
                                      const Color(0xFF00FF7F).withOpacity(
                                        0.05 * _glowAnimation.value,
                                      ),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Outer ring with border
                              Container(
                                width: 145,
                                height: 145,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00FF7F).withOpacity(
                                      0.3 *
                                          _glowAnimation.value *
                                          _pulseAnimation.value,
                                    ),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FF7F)
                                          .withOpacity(
                                            0.4 *
                                                _glowAnimation.value *
                                                _pulseAnimation.value,
                                          ),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),

                              // Inner circle with logo
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF00FF7F).withOpacity(
                                        0.15 * _glowAnimation.value,
                                      ),
                                      const Color(0xFF00FF7F).withOpacity(
                                        0.05 * _glowAnimation.value,
                                      ),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00FF7F,
                                      ).withOpacity(0.3 * _glowAnimation.value),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Image.asset(
                                    'assets/animations/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Logo loading error: $error');
                                      return const Icon(
                                        Icons.shield_outlined,
                                        size: 55,
                                        color: Color(0xFF00FF7F),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // App Name with fade and slide up
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _fadeController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFF00FF7F),
                              const Color(0xFF00D9FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'ProofIt',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF00FF7F),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Document Verification',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 70),

                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing outer ring
                          Container(
                            width: 55 * _pulseAnimation.value,
                            height: 55 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00FF7F).withOpacity(
                                  0.3 * (2 - _pulseAnimation.value),
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          // Rotating spinner
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF00FF7F),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom version text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final double progress;

  ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.1) return; // Don't show particles initially

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw subtle floating particles
    for (int i = 0; i < 15; i++) {
      final double angle = (i * 24.0) * (math.pi / 180);
      final double distance = 100 + (progress * 50);
      final double x = size.width / 2 + math.cos(angle) * distance;
      final double y = size.height / 2 + math.sin(angle) * distance;

      final double particleProgress = (progress - 0.1) / 0.9;
      final double opacity = particleProgress * (1 - particleProgress) * 4;

      paint.color = const Color(0xFF00FF7F).withOpacity(opacity * 0.15);
      canvas.drawCircle(
        Offset(x, y),
        2 + math.sin(progress * math.pi * 2 + i) * 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
