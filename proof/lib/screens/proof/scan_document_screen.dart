import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'quick_proof_creation_screen.dart';
import '../../utils/constants.dart';

class ScanDocumentScreen extends StatefulWidget {
  const ScanDocumentScreen({super.key});

  @override
  State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen>
    with SingleTickerProviderStateMixin {
  List<String> _scannedDocuments = [];
  bool _isScanning = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const neonGreen = Color(0xFF00FF7F);
  static const neonRed = Color(0xFFFF4C4C);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Auto-launch scanner when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanDocument();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _scanDocument() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      // Launch document scanner
      List<String> pictures =
          await CunningDocumentScanner.getPictures(
            noOfPages: 10, // Allow up to 10 pages
            isGalleryImportAllowed: false, // Only camera, no gallery
          ) ??
          [];

      if (pictures.isNotEmpty) {
        setState(() {
          _scannedDocuments.addAll(pictures);
        });
      } else {
        // User cancelled scanning
        if (mounted && _scannedDocuments.isEmpty) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Scanner error: $e');
      _showError('Failed to scan document: $e');
      if (mounted && _scannedDocuments.isEmpty) {
        Navigator.of(context).pop();
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _deleteDocument(int index) async {
    try {
      final file = File(_scannedDocuments[index]);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }

    setState(() {
      _scannedDocuments.removeAt(index);
    });

    // If no documents left, go back
    if (_scannedDocuments.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _proceedToProofCreation() async {
    if (_scannedDocuments.isEmpty) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuickProofCreationScreen(
          mediaFiles: _scannedDocuments.map((path) => File(path)).toList(),
          proofType: 'Document Scan',
        ),
      ),
    );

    // Pass result back to home dashboard
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: neonRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Documents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _scannedDocuments.isEmpty
            ? _buildScanningInProgress()
            : _buildDocumentsList(),
      ),
      floatingActionButton: _scannedDocuments.isNotEmpty && !_isScanning
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Add more pages button
                FloatingActionButton(
                  heroTag: 'add_more',
                  onPressed: _scanDocument,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.add, color: neonGreen),
                ),
                const SizedBox(height: 12),
                // Done button
                FloatingActionButton.extended(
                  heroTag: 'done',
                  onPressed: _proceedToProofCreation,
                  backgroundColor: neonGreen,
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: Text(
                    'Done (${_scannedDocuments.length})',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildScanningInProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: neonGreen),
          const SizedBox(height: 24),
          Text(
            'Opening scanner...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan up to 10 pages',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Column(
      children: [
        // Header info
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: neonGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.document_scanner, color: neonGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_scannedDocuments.length} ${_scannedDocuments.length == 1 ? 'Page' : 'Pages'} Scanned',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add more pages',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scanned documents grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: _scannedDocuments.length,
            itemBuilder: (context, index) {
              return _buildDocumentCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonGreen.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Document image
            Image.file(File(_scannedDocuments[index]), fit: BoxFit.cover),

            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            // Page number badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: neonGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page ${index + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: neonRed,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteDocument(index),
                ),
              ),
            ),

            // Document icon at bottom
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: neonGreen, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Enhanced',
                          style: TextStyle(
                            color: neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
