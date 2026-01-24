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
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
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

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  bool _isLoadingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  // Neon colors
  static const neonGreen = Color(0xFF00FF7F);
  static const neonRed = Color(0xFFFF4C4C);

  @override
  void initState() {
    super.initState();
    _checkPinRequirement();
    // Save last viewed proof ID
    PreferencesService.setLastProofId(widget.proofId);

    // Audio listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlayingAudio = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _audioPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
      final decryptedBytes = await _proofService.downloadAndDecryptMedia(
        url,
        iv,
      );
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

  Future<void> _playAudio(String url, String iv) async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      return;
    }

    // Resume if paused and source already set
    if (_audioPosition > Duration.zero && _audioPosition < _audioDuration) {
      await _audioPlayer.resume();
      return;
    }

    setState(() => _isLoadingAudio = true);

    try {
      final decryptedBytes = await _proofService.downloadAndDecryptAudio(
        url,
        iv,
      );

      if (decryptedBytes == null) throw Exception('Failed to decrypt audio');

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await tempFile.writeAsBytes(decryptedBytes);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play audio. Decryption error.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
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
        backgroundColor: isValid ? neonGreen : neonRed,
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
            await _loadDecryptedMedia(
              proof.mediaUrls[i],
              proof.encryptionIv!,
              key,
            );
          }
        }
      }

      // Ensure text is loaded
      if (proof.textContent != null &&
          proof.encryptionIv != null &&
          _decryptedText == null) {
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
            backgroundColor: neonRed,
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
                color: neonGreen,
              ),
            ),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {},
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: neonGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: neonGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPinVerified) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
        ),
      );
    }

    final proofProvider = context.watch<ProofProvider>();
    final proof = proofProvider.getProofById(widget.proofId);

    if (proof == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Proof Not Found',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text('Proof not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Proof Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Locked indicator
            if (proof.lockedFlag)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: neonGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: neonGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.proofLocked,
                        style: TextStyle(
                          color: neonGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Title
            Text(
              proof.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(proof.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            _buildSectionTitle('Description', Icons.description),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                proof.description ?? 'No description',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),

            // Location
            if (proof.latitude != null && proof.longitude != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Location', Icons.location_on),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: neonGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isLoadingLocation
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: neonGreen,
                              ),
                            )
                          : Text(
                              _cityName ??
                                  _locationService.formatLocation(
                                    proof.latitude,
                                    proof.longitude,
                                  ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
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
              const SizedBox(height: 24),
              _buildSectionTitle(
                'Media (${proof.mediaUrls.length})',
                Icons.photo_library,
              ),
              if (proof.encryptionIv != null)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(color: neonGreen),
                        ),
                      );
                    }

                    if (_decryptedMedia.containsKey(key)) {
                      return InkWell(
                        onTap: () {
                          final imageIndex = int.parse(key.split('_').last);
                          _viewImageGallery(imageIndex);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: neonGreen.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  _decryptedMedia[key]!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.white.withOpacity(0.05),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: neonRed,
                                      ),
                                    );
                                  },
                                ),
                                // Tap indicator
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.fullscreen,
                                      color: neonGreen,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Show error state if loading failed
                    if (_loadingMedia[key] == false &&
                        !_decryptedMedia.containsKey(key)) {
                      return Container(
                        decoration: BoxDecoration(
                          color: neonRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: neonRed.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: neonRed),
                            const SizedBox(height: 4),
                            Text(
                              'Cannot decrypt',
                              style: TextStyle(fontSize: 10, color: neonRed),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Media files (decryption key not available)',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
            ],

            // Audio
            if (proof.audioUrl != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Audio Recording', Icons.mic),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: neonGreen.withOpacity(0.2),
                          child: IconButton(
                            icon: _isLoadingAudio
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: neonGreen,
                                    ),
                                  )
                                : Icon(
                                    _isPlayingAudio
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: neonGreen,
                                  ),
                            onPressed:
                                _isLoadingAudio || proof.encryptionIv == null
                                ? null
                                : () => _playAudio(
                                    proof.audioUrl!,
                                    proof.encryptionIv!,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isPlayingAudio ? 'Playing...' : 'Audio Proof',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (proof.encryptionIv == null)
                          Tooltip(
                            message: 'Decryption key missing',
                            child: Icon(Icons.error, color: neonRed, size: 20),
                          ),
                      ],
                    ),
                    if (_audioDuration > Duration.zero)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_audioPosition),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: neonGreen,
                                  inactiveTrackColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  thumbColor: neonGreen,
                                ),
                                child: Slider(
                                  value: _audioPosition.inSeconds
                                      .toDouble()
                                      .clamp(
                                        0,
                                        _audioDuration.inSeconds.toDouble(),
                                      ),
                                  max: _audioDuration.inSeconds.toDouble(),
                                  onChanged: (v) {
                                    _audioPlayer.seek(
                                      Duration(seconds: v.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_audioDuration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Text content
            if (proof.textContent != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Text Evidence', Icons.text_fields),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Builder(
                  builder: (context) {
                    // Load decrypted text if not already loaded
                    if (_decryptedText == null &&
                        !_isLoadingText &&
                        proof.encryptionIv != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadDecryptedText(
                          proof.textContent!,
                          proof.encryptionIv!,
                        );
                      });
                    }

                    if (_isLoadingText) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: neonGreen),
                        ),
                      );
                    }

                    if (_decryptedText != null) {
                      return SelectableText(
                        _decryptedText!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      );
                    }

                    return Text(
                      'Loading decrypted text...',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Hash display
            _buildSectionTitle('Content Hash', Icons.fingerprint),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This hash is generated from all proof content. If any content is modified, the hash will change, alerting you to potential tampering.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: neonGreen.withOpacity(0.3)),
                    ),
                    child: SelectableText(
                      proof.contentHash,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: neonGreen.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _verifyIntegrity,
                      icon: const Icon(Icons.verified_user, size: 18),
                      label: const Text('Verify Integrity'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
