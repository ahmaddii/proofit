import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../proof/create_proof_screen.dart';
import '../proof/view_proofs_screen.dart';
import '../proof/scan_document_screen.dart';
import '../proof/record_video_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/pin_setup_screen.dart';
import '../../widgets/locked_proof_dialog.dart';
import 'package:lottie/lottie.dart';

// ================= COLORS =================
const Color kBgBlack = Color(0xFF0B0B0F);
const Color kNeonGreen = Color(0xFF00FF7F);
const Color kNeonGlow = Color(0x6600FF7F);

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
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

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(BuildContext context) {
    debugPrint('HomeDashboard: _showSuccessDialog called');
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => LockedProofDialog(
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _handleProofCreation(BuildContext context, Widget screen) async {
    final authProvider = context.read<AuthProvider>();
    if (!await authProvider.hasPinSetup()) {
      if (context.mounted) {
        final pinSetupResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PinSetupScreen(isMandatory: true),
          ),
        );

        if (pinSetupResult != true) {
          return; // User didn't set up PIN
        }
      }
    }

    if (!context.mounted) return;

    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen));

    if (result == true && context.mounted) {
      debugPrint('HomeDashboard: Proof created successfully, showing dialog');
      _showSuccessDialog(context);
      debugPrint('HomeDashboard: Dialog shown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = context.select<AuthProvider, String>(
      (p) => p.currentUser?.email ?? 'User',
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: kNeonGreen),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: kBgBlack,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // ================= WELCOME CARD =================
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonGlow,
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kNeonGreen.withOpacity(0.15),
                                  ),
                                  child: Lottie.asset(
                                    'assets/animations/hello.json',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Welcome back !',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userEmail,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ================= SECTION TITLE =================
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= DASHBOARD CARDS =================
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _DashboardCard(
                          icon: Icons.add_circle_outline,
                          title: AppStrings.createProof,
                          onTap: () => _handleProofCreation(
                            context,
                            const CreateProofScreen(),
                          ),
                          delay: 0,
                        ),
                        _DashboardCard(
                          icon: Icons.folder_open,
                          title: AppStrings.viewProofs,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ViewProofsScreen(),
                              ),
                            );
                          },
                          delay: 100,
                        ),
                        _DashboardCard(
                          icon: Icons.document_scanner,
                          title: 'Scan Document',
                          onTap: () => _handleProofCreation(
                            context,
                            const ScanDocumentScreen(),
                          ),
                          delay: 200,
                        ),
                        _DashboardCard(
                          icon: Icons.videocam,
                          title: 'Record Video',
                          onTap: () => _handleProofCreation(
                            context,
                            const RecordVideoScreen(),
                          ),
                          delay: 300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= DASHBOARD CARD =================
class _DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int delay;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.delay = 0,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: kNeonGreen,
              boxShadow: [
                BoxShadow(color: kNeonGlow, blurRadius: 30, spreadRadius: 3),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 48, color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
