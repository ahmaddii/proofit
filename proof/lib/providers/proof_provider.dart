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

  List<ProofModel> get proofs => _proofs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all user proofs
  Future<void> loadProofs() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _proofs = await _proofService.getUserProofs();
      
      // Save sync time
      await PreferencesService.setLastSyncTime(DateTime.now());
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new proof
  Future<bool> createProof({
    required String title,
    required String description,
    List<File>? mediaFiles,
    File? audioFile,
    String? textContent,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final proof = await _proofService.createProof(
        title: title,
        description: description,
        mediaFiles: mediaFiles,
        audioFile: audioFile,
        textContent: textContent,
        latitude: latitude,
        longitude: longitude,
      );

      _proofs.insert(0, proof);
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Lock proof
  Future<bool> lockProof(String proofId) async {
    try {
      final success = await _proofService.lockProof(proofId);
      
      if (success) {
        final index = _proofs.indexWhere((p) => p.proofId == proofId);
        if (index != -1) {
          _proofs[index] = _proofs[index].copyWith(lockedFlag: true);
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete proof
  Future<bool> deleteProof(String proofId) async {
    try {
      final success = await _proofService.deleteProof(proofId);
      
      if (success) {
        _proofs.removeWhere((p) => p.proofId == proofId);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
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
      return null;
    }
  }

  // Verify proof integrity
  Future<bool> verifyProofIntegrity(ProofModel proof) async {
    return await _proofService.verifyProofIntegrity(proof);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}