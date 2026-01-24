import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/proof_provider.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

class CreateProofScreen extends StatefulWidget {
  const CreateProofScreen({super.key});

  @override
  State<CreateProofScreen> createState() => _CreateProofScreenState();
}

class _CreateProofScreenState extends State<CreateProofScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textContentController = TextEditingController();

  final List<File> _mediaFiles = [];
  File? _audioFile;
  final _imagePicker = ImagePicker();
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  bool _isRecording = false;
  bool _isUploading = false;
  bool _isPlaying = false;
  bool _includeLocation = true;
  double? _latitude;
  double? _longitude;

  // Recording UI state
  Duration _recordingDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _recordingTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _locationService = LocationService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Neon colors
  static const neonGreen = Color(0xFF00FF7F);
  static const neonRed = Color(0xFFFF4C4C);

  @override
  void initState() {
    super.initState();

    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();

    // Pulse animation for recording indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Audio player listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackDuration = position;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _textContentController.dispose();

    // Safely dispose audio resources
    _disposeAudioResources();

    _fadeController.dispose();
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _disposeAudioResources() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
      _audioRecorder.dispose();
    } catch (e) {
      debugPrint('Error disposing audio recorder: $e');
    }

    try {
      await _audioPlayer.stop();
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _mediaFiles.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        setState(() {
          _mediaFiles.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showError('Microphone permission denied');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);

      setState(() {
        _isRecording = true;
        _audioFile = null; // Clear previous recording
      });

      _startRecordingTimer();
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _stopRecordingTimer();

      if (path != null) {
        setState(() {
          _audioFile = File(path);
          _isRecording = false;
          _totalDuration = _recordingDuration;
        });
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    await _audioRecorder.stop();
    _stopRecordingTimer();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _togglePlayback() async {
    if (_audioFile == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioFile!.path));
      }
    } catch (e) {
      _showError('Failed to play audio: $e');
    }
  }

  Future<void> _getLocation() async {
    if (!_includeLocation) return;

    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }
  }

  Future<void> _createProof() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mediaFiles.isEmpty &&
        _audioFile == null &&
        _textContentController.text.isEmpty) {
      _showError(
        'Please add at least one piece of evidence (photo, audio, or text)',
      );
      return;
    }

    setState(() => _isUploading = true);

    // Get location if enabled
    await _getLocation();

    final proofProvider = context.read<ProofProvider>();
    final success = await proofProvider.createProof(
      title: _titleController.text,
      description: _descriptionController.text,
      mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
      audioFile: _audioFile,
      textContent: _textContentController.text.isNotEmpty
          ? _textContentController.text
          : null,
      latitude: _latitude,
      longitude: _longitude,
    );

    setState(() => _isUploading = false);

    if (!mounted) return;

    if (success) {
      // Return true to indicate success to previous screen
      Navigator.of(context).pop(true);
    } else {
      _showError(proofProvider.errorMessage ?? 'Failed to create proof');
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: neonGreen.withOpacity(0.7),
          letterSpacing: 1,
        ),
      ),
    );
  }

  // WhatsApp-style voice message recorder
  Widget _buildVoiceRecorder() {
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: neonRed.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel button
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: neonRed,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Pulsing red dot
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: neonRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: neonRed.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Recording duration
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(width: 8),

            // Slide to cancel text
            Flexible(
              child: Text(
                '< Slide to cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 12),

            // Stop button
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: neonGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 24),
              ),
            ),
          ],
        ),
      );
    }

    // Not recording - show record button
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: neonGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: neonGreen, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: neonGreen, size: 24),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Hold to Record Voice',
                style: TextStyle(
                  color: neonGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recorded audio preview (WhatsApp style)
  Widget _buildAudioPreview() {
    if (_audioFile == null) return const SizedBox.shrink();

    final progress = _totalDuration.inMilliseconds > 0
        ? _playbackDuration.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: neonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: neonGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Waveform and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform with progress
                Stack(
                  children: [
                    // Background waveform
                    Row(
                      children: List.generate(
                        30,
                        (index) => Container(
                          width: 3,
                          height: (index % 5 + 1) * 4.0,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: neonGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Progress overlay
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Row(
                          children: List.generate(
                            30,
                            (index) => Container(
                              width: 3,
                              height: (index % 5 + 1) * 4.0,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: neonGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying
                      ? _formatDuration(_playbackDuration)
                      : _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: neonRed),
            onPressed: () {
              _audioPlayer.stop();
              setState(() {
                _audioFile = null;
                _recordingDuration = Duration.zero;
                _playbackDuration = Duration.zero;
                _totalDuration = Duration.zero;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          AppStrings.createProof,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: AppStrings.title,
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonGreen, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonRed),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonRed, width: 2),
                    ),
                    errorStyle: TextStyle(color: neonRed),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: AppStrings.description,
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonGreen, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonRed),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonRed, width: 2),
                    ),
                    errorStyle: TextStyle(color: neonRed),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Text content
                TextFormField(
                  controller: _textContentController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Additional Text Evidence (optional)',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: neonGreen, width: 2),
                    ),
                  ),
                ),

                // Media Evidence Section
                _buildSectionHeader('Media Evidence'),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _capturePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_mediaFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _mediaFiles.asMap().entries.map((entry) {
                      return Container(
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
                            children: [
                              Image.file(
                                entry.value,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: neonRed,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _mediaFiles.removeAt(entry.key);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Audio Evidence Section (WhatsApp Style)
                _buildSectionHeader('Audio Evidence'),

                _buildVoiceRecorder(),
                _buildAudioPreview(),

                // Location Toggle
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Include GPS Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Adds geographical coordinates to your proof',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    value: _includeLocation,
                    activeColor: neonGreen,
                    onChanged: (value) {
                      setState(() {
                        _includeLocation = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Create button
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _createProof,
                  icon: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Icon(Icons.lock),
                  label: Text(
                    _isUploading ? 'Creating...' : 'Create & Lock Proof',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.white.withOpacity(0.2),
                    disabledForegroundColor: Colors.white.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 16),

                // Info message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Once created, this proof cannot be edited or deleted',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
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
        ),
      ),
    );
  }
}
