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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProofProvider>().loadProofs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.viewProofs)),
      body: Consumer<ProofProvider>(
        builder: (context, proofProvider, child) {
          if (proofProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (proofProvider.proofs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No proofs yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: proofProvider.proofs.length,
            itemBuilder: (context, index) {
              final proof = proofProvider.proofs[index];
              return ProofCard(
                proof: proof,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProofDetailScreen(proofId: proof.proofId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
