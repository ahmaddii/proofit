import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/proof_model.dart';
import '../config/supabase_config.dart';
import 'encryption_service.dart';

class ProofService {
  final _supabase = Supabase.instance.client;

  // Create new proof
  Future<ProofModel> createProof({
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      List<String> mediaUrls = [];
      String? videoUrl;
      String? audioUrl;
      String? encryptionIv;

      // Generate a single IV for all files in this proof
      // This ensures we can decrypt all files with the same IV
      final sharedIv = encrypt.IV.fromSecureRandom(16);
      encryptionIv = sharedIv.base64;

      // Upload media files
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (int i = 0; i < mediaFiles.length; i++) {
          final file = mediaFiles[i];
          final bytes = await file.readAsBytes();

          // Encrypt file with shared IV
          final encrypted = await EncryptionService.encryptFileBytesWithIv(
            bytes,
            sharedIv.base64,
          );

          final fileName =
              '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.enc';

          await _supabase.storage
              .from(SupabaseConfig.mediaStorageBucket)
              .uploadBinary(fileName, encrypted['encryptedBytes'] as Uint8List);

          final url = _supabase.storage
              .from(SupabaseConfig.mediaStorageBucket)
              .getPublicUrl(fileName);

          mediaUrls.add(url);
        }
      }

      // Upload video file
      if (videoFile != null) {
        final bytes = await videoFile.readAsBytes();
        final encrypted = await EncryptionService.encryptFileBytesWithIv(
          bytes,
          sharedIv.base64,
        );

        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}_video.enc';

        await _supabase.storage
            .from(SupabaseConfig.videoStorageBucket)
            .uploadBinary(fileName, encrypted['encryptedBytes'] as Uint8List);

        videoUrl = _supabase.storage
            .from(SupabaseConfig.videoStorageBucket)
            .getPublicUrl(fileName);
      }

      // Upload audio file
      if (audioFile != null) {
        final bytes = await audioFile.readAsBytes();
        // Encrypt audio with shared IV
        final encrypted = await EncryptionService.encryptFileBytesWithIv(
          bytes,
          sharedIv.base64,
        );

        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}_audio.enc';

        await _supabase.storage
            .from(SupabaseConfig.audioStorageBucket)
            .uploadBinary(fileName, encrypted['encryptedBytes'] as Uint8List);

        audioUrl = _supabase.storage
            .from(SupabaseConfig.audioStorageBucket)
            .getPublicUrl(fileName);
      }

      // Encrypt text content if provided
      String? encryptedText;
      if (textContent != null && textContent.isNotEmpty) {
        // Encrypt text with shared IV
        final encrypted = await EncryptionService.encryptDataWithIv(
          textContent,
          sharedIv.base64,
        );
        encryptedText = encrypted['encrypted'];
      }

      final timestamp = DateTime.now();

      // Generate hash for tamper detection
      final hash = EncryptionService.generateProofHash(
        title: title,
        description: description,
        timestamp: timestamp,
        mediaUrls: mediaUrls,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        textContent: encryptedText,
      );

      // Insert proof into database
      final response = await _supabase
          .from('proofs')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'timestamp': timestamp.toIso8601String(),
            'locked_flag': false,
            'latitude': latitude,
            'longitude': longitude,
            'media_urls': mediaUrls,
            'video_url': videoUrl,
            'audio_url': audioUrl,
            'text_content': encryptedText,
            'content_hash': hash,
            'encryption_iv': encryptionIv,
          })
          .select()
          .single();

      return ProofModel.fromJson(response);
    } catch (e) {
      print('Error creating proof: $e');
      rethrow;
    }
  }

  // Get all proofs for current user
  Future<List<ProofModel>> getUserProofs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('proofs')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => ProofModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching proofs: $e');
      rethrow;
    }
  }

  // Get single proof by ID
  Future<ProofModel?> getProofById(String proofId) async {
    try {
      final response = await _supabase
          .from('proofs')
          .select()
          .eq('proof_id', proofId)
          .maybeSingle();

      if (response == null) return null;
      return ProofModel.fromJson(response);
    } catch (e) {
      print('Error fetching proof: $e');
      return null;
    }
  }

  // Lock proof (cannot be edited/deleted after this)
  Future<bool> lockProof(String proofId) async {
    try {
      await _supabase
          .from('proofs')
          .update({'locked_flag': true})
          .eq('proof_id', proofId);

      return true;
    } catch (e) {
      print('Error locking proof: $e');
      return false;
    }
  }

  // Delete proof (only if not locked)
  Future<bool> deleteProof(String proofId) async {
    try {
      // Check if locked
      final proof = await getProofById(proofId);
      if (proof == null) return false;
      if (proof.lockedFlag) {
        throw Exception('Cannot delete locked proof');
      }

      await _supabase.from('proofs').delete().eq('proof_id', proofId);
      return true;
    } catch (e) {
      print('Error deleting proof: $e');
      return false;
    }
  }

  // Download and decrypt media file
  Future<Uint8List?> downloadAndDecryptMedia(String url, String iv) async {
    try {
      // Extract file path from URL
      // URL format: https://...supabase.co/storage/v1/object/public/proof-media/userId/filename
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(
        SupabaseConfig.mediaStorageBucket,
      );

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid URL format');
      }

      // Get the file path after bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      final response = await _supabase.storage
          .from(SupabaseConfig.mediaStorageBucket)
          .download(filePath);

      // Try to decrypt with the provided IV
      try {
        return await EncryptionService.decryptFileBytes(response, iv);
      } catch (e) {
        // If decryption fails, it might be an old proof encrypted with a different IV
        // For now, return null and let the UI handle it gracefully
        print('Decryption failed for file: $filePath. Error: $e');
        print('This might be an older proof encrypted with a different IV.');
        return null;
      }
    } catch (e) {
      print('Error downloading media: $e');
      return null;
    }
  }

  // Download and decrypt audio file
  Future<Uint8List?> downloadAndDecryptAudio(String url, String iv) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(
        SupabaseConfig.audioStorageBucket,
      );

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      final response = await _supabase.storage
          .from(SupabaseConfig.audioStorageBucket)
          .download(filePath);

      return await EncryptionService.decryptFileBytes(response, iv);
    } catch (e) {
      print('Error downloading audio: $e');
      return null;
    }
  }

  // Download and decrypt video file
  Future<Uint8List?> downloadAndDecryptVideo(String url, String iv) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(
        SupabaseConfig.videoStorageBucket,
      );

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      final response = await _supabase.storage
          .from(SupabaseConfig.videoStorageBucket)
          .download(filePath);

      return await EncryptionService.decryptFileBytes(response, iv);
    } catch (e) {
      print('Error downloading video: $e');
      return null;
    }
  }

  // Verify proof integrity
  Future<bool> verifyProofIntegrity(ProofModel proof) async {
    try {
      final computedHash = EncryptionService.generateProofHash(
        title: proof.title,
        description: proof.description ?? '',
        timestamp: proof.timestamp,
        mediaUrls: proof.mediaUrls,
        videoUrl: proof.videoUrl,
        audioUrl: proof.audioUrl,
        textContent: proof.textContent,
      );

      return computedHash == proof.contentHash;
    } catch (e) {
      print('Error verifying proof: $e');
      return false;
    }
  }
}
