import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const String _encryptionKeyStorageKey = 'encryption_master_key';

  // Generate or retrieve encryption key with file backup
  static Future<encrypt.Key> _getEncryptionKey() async {
    try {
      // 1. Try Secure Storage
      String? storedKey = await _storage.read(key: _encryptionKeyStorageKey);

      if (storedKey != null) {
        // Ensure backup exists
        await _backupKeyToFile(storedKey);
        return encrypt.Key(base64Decode(storedKey));
      }

      // 2. Try File Backup
      final backupKey = await _getKeyFromBackup();
      if (backupKey != null) {
        // Restore to Secure Storage
        await _storage.write(key: _encryptionKeyStorageKey, value: backupKey);
        return encrypt.Key(base64Decode(backupKey));
      }

      // 3. Generate New Key
      final key = encrypt.Key.fromSecureRandom(32);
      final keyString = base64Encode(key.bytes);

      // Save to both locations
      await _storage.write(key: _encryptionKeyStorageKey, value: keyString);
      await _backupKeyToFile(keyString);

      return key;
    } catch (e) {
      // Emergency fallback if secure storage crashes completely
      print('Secure storage error: $e');
      final backupKey = await _getKeyFromBackup();
      if (backupKey != null) {
        return encrypt.Key(base64Decode(backupKey));
      }
      rethrow;
    }
  }

  static Future<void> _backupKeyToFile(String keyString) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.proofit_key_backup');
      if (!await file.exists()) {
        await file.writeAsString(keyString);
      }
    } catch (e) {
      print('Key backup failed: $e');
    }
  }

  static Future<String?> _getKeyFromBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.proofit_key_backup');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Reading key backup failed: $e');
    }
    return null;
  }

  // Encrypt data
  static Future<Map<String, String>> encryptData(String plainText) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      return {'encrypted': encrypted.base64, 'iv': iv.base64};
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  // Encrypt data with a specific IV (for shared IV across files)
  static Future<Map<String, String>> encryptDataWithIv(
    String plainText,
    String ivBase64,
  ) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      return {'encrypted': encrypted.base64, 'iv': iv.base64};
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  // Decrypt data
  static Future<String> decryptData(
    String encryptedText,
    String ivBase64,
  ) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return encrypter.decrypt64(encryptedText, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  // Encrypt file bytes
  static Future<Map<String, dynamic>> encryptFileBytes(Uint8List bytes) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encryptBytes(bytes, iv: iv);

      return {'encryptedBytes': encrypted.bytes, 'iv': iv.base64};
    } catch (e) {
      throw Exception('File encryption failed: $e');
    }
  }

  // Encrypt file bytes with a specific IV (for shared IV across files)
  static Future<Map<String, dynamic>> encryptFileBytesWithIv(
    Uint8List bytes,
    String ivBase64,
  ) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encryptBytes(bytes, iv: iv);

      return {'encryptedBytes': encrypted.bytes, 'iv': iv.base64};
    } catch (e) {
      throw Exception('File encryption failed: $e');
    }
  }

  // Decrypt file bytes
  static Future<Uint8List> decryptFileBytes(
    Uint8List encryptedBytes,
    String ivBase64,
  ) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return Uint8List.fromList(
        encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv),
      );
    } catch (e) {
      throw Exception('File decryption failed: $e');
    }
  }

  // Generate SHA-256 hash for tamper detection
  static String generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify hash
  static bool verifyHash(String content, String storedHash) {
    final computedHash = generateHash(content);
    return computedHash == storedHash;
  }

  // Generate hash from multiple data sources
  static String generateProofHash({
    required String title,
    required String description,
    required DateTime timestamp,
    required List<String> mediaUrls,
    String? audioUrl,
    String? textContent,
  }) {
    final combined =
        '$title|$description|${timestamp.toIso8601String()}|'
        '${mediaUrls.join(',')}|${audioUrl ?? ''}|${textContent ?? ''}';
    return generateHash(combined);
  }
}
