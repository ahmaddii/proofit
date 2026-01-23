import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../providers/proof_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/proof_service.dart';
import '../../services/encryption_service.dart';
import '../../services/pdf_service.dart';
import '../../services/preferences_service.dart';
import '../../utils/constants.dart';
import 'pin_verification_screen.dart';

class ProofDetailScreen extends StatefulWidget {
  final String proofId;

  const ProofDetailScreen({super.key, required this.proofId});

  @override
  State<ProofDetailScreen> createState() => _ProofDetailScreenState();
}

class _ProofDetailScreenState extends State<ProofDetailScreen> {
  bool _isPinVerified = false;
  final _locationService = LocationService();
  final _proofService = ProofService();
  final _pdfService = PdfService();
  
  String? _cityName;
  bool _isLoadingLocation = false;
  Map<String, Uint8List> _decryptedMedia = {};
  Map<String, bool> _loadingMedia = {};
  String? _decryptedText;
  bool _isLoadingText = false;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _checkPinRequirement();
    // Save last viewed proof ID
    PreferencesService.setLastProofId(widget.proofId);
  }

  Future<void> _loadLocationName(double latitude, double longitude) async {
    setState(() => _isLoadingLocation = true);
    try {
      final cityName = await _locationService.getCityName(latitude, longitude);
      if (mounted) {
        setState(() {
          _cityName = cityName;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cityName = _locationService.formatLocation(latitude, longitude);
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadDecryptedMedia(String url, String iv, String key) async {
    if (_decryptedMedia.containsKey(key) || _loadingMedia[key] == true) {
      return;
    }

    setState(() => _loadingMedia[key] = true);
    try {
      final decryptedBytes = await _proofService.downloadAndDecryptMedia(url, iv);
      if (mounted) {
        setState(() {
          if (decryptedBytes != null) {
            _decryptedMedia[key] = decryptedBytes;
          }
          _loadingMedia[key] = false;
        });
      }
    } catch (e) {
      print('Error loading media: $e');
      if (mounted) {
        setState(() => _loadingMedia[key] = false);
      }
    }
  }

  Future<void> _loadDecryptedText(String encryptedText, String iv) async {
    if (_decryptedText != null || _isLoadingText) {
      return;
    }

    setState(() => _isLoadingText = true);
    try {
      final decrypted = await EncryptionService.decryptData(encryptedText, iv);
      if (mounted) {
        setState(() {
          _decryptedText = decrypted;
          _isLoadingText = false;
        });
      }
    } catch (e) {
      print('Error decrypting text: $e');
      if (mounted) {
        setState(() {
          _decryptedText = 'Failed to decrypt text content';
          _isLoadingText = false;
        });
      }
    }
  }

  Future<void> _checkPinRequirement() async {
    final authProvider = context.read<AuthProvider>();
    final hasPinSetup = await authProvider.hasPinSetup();

    if (!hasPinSetup) {
      // No PIN setup, allow direct access
      setState(() => _isPinVerified = true);
    } else {
      // Require PIN verification
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PinVerificationScreen(
              proofId: widget.proofId,
              onSuccess: () {
                setState(() => _isPinVerified = true);
              },
            ),
          ),
        );

        if (result != true && mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _verifyIntegrity() async {
    final proofProvider = context.read<ProofProvider>();
    final proof = proofProvider.getProofById(widget.proofId);

    if (proof == null) return;

    final isValid = await proofProvider.verifyProofIntegrity(proof);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isValid
              ? '✓ Proof integrity verified'
              : '✗ Warning: Proof may have been tampered with',
        ),
        backgroundColor: isValid ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    final proofProvider = context.read<ProofProvider>();
    final proof = proofProvider.getProofById(widget.proofId);
    
    if (proof == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      // Ensure all media is loaded
      if (proof.mediaUrls.isNotEmpty && proof.encryptionIv != null) {
        for (int i = 0; i < proof.mediaUrls.length; i++) {
          final key = 'media_$i';
          if (!_decryptedMedia.containsKey(key) && _loadingMedia[key] != true) {
            await _loadDecryptedMedia(proof.mediaUrls[i], proof.encryptionIv!, key);
          }
        }
      }

      // Ensure text is loaded
      if (proof.textContent != null && proof.encryptionIv != null && _decryptedText == null) {
        await _loadDecryptedText(proof.textContent!, proof.encryptionIv!);
      }

      // Generate and share PDF
      await _pdfService.generateAndShareProofPdf(
        proof: proof,
        decryptedMedia: _decryptedMedia.isNotEmpty ? _decryptedMedia : null,
        decryptedText: _decryptedText,
        cityName: _cityName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  void _viewImageGallery(int initialIndex) {
    final images = _decryptedMedia.entries.toList();
    if (images.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: MemoryImage(images[index].value),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: images.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPinVerified) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final proofProvider = context.watch<ProofProvider>();
    final proof = proofProvider.getProofById(widget.proofId);

    if (proof == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proof Not Found')),
        body: const Center(child: Text('Proof not found')),
      );
    }

    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm:ss a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: _verifyIntegrity,
            tooltip: 'Verify Integrity',
          ),
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Locked indicator
            if (proof.lockedFlag)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.successColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.proofLocked,
                        style: TextStyle(
                          color: AppColors.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Title
            Text(
              proof.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Timestamp
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(proof.timestamp),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(proof.description ?? 'No description'),
                  ],
                ),
              ),
            ),

            // Location
            if (proof.latitude != null && proof.longitude != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _cityName ?? _locationService.formatLocation(
                                      proof.latitude,
                                      proof.longitude,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_cityName == null && !_isLoadingLocation)
                Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadLocationName(proof.latitude!, proof.longitude!);
                    });
                    return const SizedBox.shrink();
                  },
                ),
            ],

            // Media
            if (proof.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media (${proof.mediaUrls.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (proof.encryptionIv != null)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: proof.mediaUrls.length,
                          itemBuilder: (context, index) {
                            final url = proof.mediaUrls[index];
                            final key = 'media_$index';
                            
                            // Load media if not already loaded
                            if (!_decryptedMedia.containsKey(key) && 
                                _loadingMedia[key] != true &&
                                proof.encryptionIv != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _loadDecryptedMedia(url, proof.encryptionIv!, key);
                              });
                            }
                            
                            if (_loadingMedia[key] == true) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            if (_decryptedMedia.containsKey(key)) {
                              return InkWell(
                                onTap: () {
                                  final imageIndex = int.parse(key.split('_').last);
                                  _viewImageGallery(imageIndex);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        _decryptedMedia[key]!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image),
                                          );
                                        },
                                      ),
                                      // Subtle indicator that image is tappable
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            // Show error state if loading failed
                            if (_loadingMedia[key] == false && !_decryptedMedia.containsKey(key)) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.orange[700]),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'Cannot decrypt',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image),
                            );
                          },
                        )
                      else
                        const Text('Media files (decryption key not available)'),
                    ],
                  ),
                ),
              ),
            ],

            // Audio
            if (proof.audioUrl != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Recording',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Encrypted audio file attached'),
                    ],
                  ),
                ),
              ),
            ],

            // Text content
            if (proof.textContent != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text Evidence',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Load decrypted text if not already loaded
                          if (_decryptedText == null && 
                              !_isLoadingText &&
                              proof.encryptionIv != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _loadDecryptedText(proof.textContent!, proof.encryptionIv!);
                            });
                          }
                          
                          if (_isLoadingText) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          if (_decryptedText != null) {
                            return SelectableText(
                              _decryptedText!,
                              style: const TextStyle(fontSize: 14),
                            );
                          }
                          
                          return const Text('Loading decrypted text...');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Hash display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fingerprint, color: AppColors.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Content Hash (Tamper Detection)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This hash is generated from all proof content (title, description, timestamp, media, audio, and text). If any content is modified, the hash will change, alerting you to potential tampering.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        proof.contentHash,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _verifyIntegrity,
                      icon: const Icon(Icons.verified_user, size: 18),
                      label: const Text('Verify Integrity'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successColor,
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
}