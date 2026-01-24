import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/proof_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/proof_card.dart';
import 'proof_detail_screen.dart';

class ViewProofsScreen extends StatefulWidget {
  const ViewProofsScreen({super.key});

  @override
  State<ViewProofsScreen> createState() => _ViewProofsScreenState();
}

class _ViewProofsScreenState extends State<ViewProofsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Neon green accent
  static const neonGreen = Color(0xFF00FF7F);

  @override
  void initState() {
    super.initState();

    // Load proofs after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProofProvider>().loadProofs();
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Glass card wrapper
  Widget _glassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(color: neonGreen.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          AppStrings.viewProofs,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ProofProvider>(
        builder: (context, proofProvider, child) {
          if (proofProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: neonGreen,
                strokeWidth: 3,
              ),
            );
          }

          if (proofProvider.proofs.isEmpty) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: neonGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.folder_open,
                        size: 80,
                        color: neonGreen.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No proofs yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first proof to get started',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.5), // fixed opacity
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: proofProvider.proofs.length,
              itemBuilder: (context, index) {
                final proof = proofProvider.proofs[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ), // safe clamp
                    );
                  },
                  child: _glassCard(
                    child: ProofCard(
                      proof: proof,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProofDetailScreen(proofId: proof.proofId),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
