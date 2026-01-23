import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
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

class _CreateProofScreenState extends State<CreateProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textContentController = TextEditingController();
  
  final List<File> _mediaFiles = [];
  File? _audioFile;
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isUploading = false;
  bool _includeLocation = true;
  double? _latitude;
  double? _longitude;
  
  final _locationService = LocationService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _textContentController.dispose();
    _audioRecorder.dispose();
    super.dispose();
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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _audioFile = File(path);
          _isRecording = false;
        });
      }
    } else {
      // Request microphone permission
      if (await Permission.microphone.request().isGranted) {
        // Start recording
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
        });
      } else {
        _showError('Microphone permission denied');
      }
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
    
    if (_mediaFiles.isEmpty && _audioFile == null && _textContentController.text.isEmpty) {
      _showError('Please add at least one piece of evidence (photo, audio, or text)');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof created successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      _showError(proofProvider.errorMessage ?? 'Failed to create proof');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createProof),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppStrings.title,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
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
                  decoration: InputDecoration(
                    labelText: AppStrings.description,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Text content (optional)
                TextFormField(
                  controller: _textContentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Additional Text Evidence (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Media section
                Text(
                  'Media Evidence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryColor,
                          side: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _capturePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryColor,
                          side: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_mediaFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mediaFiles.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Image.file(
                            entry.value,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _mediaFiles.removeAt(entry.key);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Audio recording
                Text(
                  'Audio Evidence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                
                ElevatedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : AppColors.primaryColor,
                  ),
                ),
                
                if (_audioFile != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.successColor),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Audio recorded')),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _audioFile = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Location toggle
                SwitchListTile(
                  title: const Text('Include GPS Location'),
                  value: _includeLocation,
                  onChanged: (value) {
                    setState(() {
                      _includeLocation = value;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Create & Lock button
                ElevatedButton(
                  onPressed: _isUploading ? null : _createProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create & Lock Proof',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Note: Once created, this proof cannot be edited or deleted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}