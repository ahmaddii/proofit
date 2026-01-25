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

class _ViewProofsScreenState extends State<ViewProofsScreen> {
  static const neonGreen = Color(0xFF00FF7F);

  @override
  void initState() {
    super.initState();
    // Safety check: ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProofProvider>().loadProofs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('View Proofs'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ProofProvider>(
        builder: (context, proofProvider, child) {
          if (proofProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: neonGreen),
            );
          }

          if (proofProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${proofProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (proofProvider.proofs.isEmpty) {
            return const Center(
              child: Text(
                'No proofs found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: proofProvider.proofs.length,
            itemBuilder: (context, index) {
              final proof = proofProvider.proofs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
              );
            },
          );
        },
      ),
    );
  }
}
