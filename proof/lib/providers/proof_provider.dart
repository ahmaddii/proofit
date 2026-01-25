import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/proof_model.dart';
import '../services/proof_service.dart';
import '../services/preferences_service.dart';

class ProofProvider with ChangeNotifier {
  final ProofService _proofService = ProofService();

  List<ProofModel> _proofs = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  List<ProofModel> get proofs => _proofs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all user proofs
  Future<void> loadProofs() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) {
      debugPrint('Already loading proofs, skipping...');
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Starting to load proofs...');

      final loadedProofs = await _proofService.getUserProofs();

      debugPrint('Loaded ${loadedProofs.length} proofs');

      _proofs = loadedProofs;
      _hasLoaded = true;

      // Save sync time
      await PreferencesService.setLastSyncTime(DateTime.now());

      _errorMessage = null;
    } catch (e) {
      debugPrint('Error loading proofs: $e');
      _errorMessage = e.toString();
      _proofs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh proofs (force reload)
  Future<void> refreshProofs() async {
    _hasLoaded = false;
    await loadProofs();
  }

  // Create new proof
  Future<bool> createProof({
    required String title,
    required String description,
    List<File>? mediaFiles,
    File? videoFile,
    File? audioFile,
    String? textContent,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Creating proof: $title');

      final proof = await _proofService.createProof(
        title: title,
        description: description,
        mediaFiles: mediaFiles,
        videoFile: videoFile,
        audioFile: audioFile,
        textContent: textContent,
        latitude: latitude,
        longitude: longitude,
      );

      debugPrint('Proof created successfully: ${proof.proofId}');

      _proofs.insert(0, proof);
      _errorMessage = null;

      return true;
    } catch (e) {
      debugPrint('Error creating proof: $e');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lock proof
  Future<bool> lockProof(String proofId) async {
    try {
      debugPrint('Locking proof: $proofId');

      final success = await _proofService.lockProof(proofId);

      if (success) {
        final index = _proofs.indexWhere((p) => p.proofId == proofId);
        if (index != -1) {
          // Create a new ProofModel with locked flag set to true
          final updatedProof = ProofModel(
            proofId: _proofs[index].proofId,
            userId: _proofs[index].userId,
            title: _proofs[index].title,
            description: _proofs[index].description,
            timestamp: _proofs[index].timestamp,
            lockedFlag: true, // Set to true
            latitude: _proofs[index].latitude,
            longitude: _proofs[index].longitude,
            mediaUrls: _proofs[index].mediaUrls,
            audioUrl: _proofs[index].audioUrl,
            textContent: _proofs[index].textContent,
            contentHash: _proofs[index].contentHash,
            encryptionIv: _proofs[index].encryptionIv,
            createdAt: _proofs[index].createdAt,
            updatedAt: DateTime.now(), // Update timestamp when locking
          );

          _proofs[index] = updatedProof;
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error locking proof: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete proof
  Future<bool> deleteProof(String proofId) async {
    try {
      debugPrint('Deleting proof: $proofId');

      final success = await _proofService.deleteProof(proofId);

      if (success) {
        _proofs.removeWhere((p) => p.proofId == proofId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting proof: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get proof by ID
  ProofModel? getProofById(String proofId) {
    try {
      return _proofs.firstWhere((p) => p.proofId == proofId);
    } catch (e) {
      debugPrint('Proof not found: $proofId');
      return null;
    }
  }

  // Verify proof integrity
  Future<bool> verifyProofIntegrity(ProofModel proof) async {
    try {
      return await _proofService.verifyProofIntegrity(proof);
    } catch (e) {
      debugPrint('Error verifying proof integrity: $e');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
