import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF000000)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle grid pattern
            CustomPaint(painter: GridPainter(), size: Size.infinite),

            // Animated glow orbs
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: OrbPainter(_shimmerController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00FF7F,
                                        ).withOpacity(0.2),
                                        blurRadius: 80,
                                        spreadRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),

                                // Hexagon effect ring
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(
                                        0xFF00FF7F,
                                      ).withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                ),

                                // Main logo container
                                Container(
                                  width: 115,
                                  height: 115,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(
                                          0xFF00FF7F,
                                        ).withOpacity(0.15),
                                        const Color(0xFF000000),
                                      ],
                                      stops: const [0.0, 1.0],
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF00FF7F,
                                      ).withOpacity(0.4),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00FF7F,
                                        ).withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      color: const Color(0xFF000000),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(28.0),
                                          child: Image.asset(
                                            'assets/animations/logo.png',
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.verified_user_rounded,
                                                    size: 48,
                                                    color: Color(0xFF00FF7F),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 50),

                      // App name with shimmer effect
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: const [
                                  Color(0xFFFFFFFF),
                                  Color(0xFF00FF7F),
                                  Color(0xFFFFFFFF),
                                ],
                                stops: [0.0, _shimmerController.value, 1.0],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'ProofIt',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 46,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                height: 1.2,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tagline
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        child: const Text(
                          'BlockChain Based Document Security',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00FF7F),
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Security features
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureBadge(Icons.lock_outline, 'ENCRYPTED'),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 14,
                            color: const Color(0xFF00FF7F).withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureBadge(
                            Icons.verified_outlined,
                            'VERIFIED',
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 14,
                            color: const Color(0xFF00FF7F).withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureBadge(Icons.shield_outlined, 'SECURE'),
                        ],
                      ),

                      const SizedBox(height: 70),

                      // Loading indicator
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00FF7F,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00FF7F),
                                      ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom info
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF00FF7F).withOpacity(0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enterprise Grade Security',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF00FF7F).withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00FF7F).withOpacity(0.6),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// Professional grid pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF7F).withOpacity(0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 50.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}

// Subtle animated orbs
class OrbPainter extends CustomPainter {
  final double progress;

  OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top right orb
    paint.color = const Color(0xFF00FF7F).withOpacity(0.04);
    final topRightOffset = Offset(
      size.width * 0.85 + math.sin(progress * 2 * math.pi) * 15,
      size.height * 0.15 + math.cos(progress * 2 * math.pi) * 20,
    );
    canvas.drawCircle(topRightOffset, 120, paint);

    // Bottom left orb
    paint.color = const Color(0xFF00FF7F).withOpacity(0.03);
    final bottomLeftOffset = Offset(
      size.width * 0.15 - math.sin(progress * 2 * math.pi) * 20,
      size.height * 0.85 - math.cos(progress * 2 * math.pi) * 15,
    );
    canvas.drawCircle(bottomLeftOffset, 150, paint);
  }

  @override
  bool shouldRepaint(OrbPainter oldDelegate) => true;
}
