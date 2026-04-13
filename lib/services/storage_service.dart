import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ── Image Picking ─────────────────────────────────────────

  Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (picked != null) return File(picked.path);
    return null;
  }

  Future<List<File>> pickMultipleImages({int maxCount = 3}) async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1024,
    );
    // Limit count
    final limited = picked.take(maxCount).toList();
    return limited.map((xf) => File(xf.path)).toList();
  }

  // ── Upload helpers ────────────────────────────────────────

  /// Stores under `profile_images/{uid}/{uid}_{yyyyMMdd_HHmmss}_{ms}.jpg`.
  /// Optionally removes [replacePreviousDownloadUrl] after a successful upload
  /// (e.g. old profile photo in the same bucket).
  Future<String?> uploadProfileImage(
    String uid,
    File file, {
    String? replacePreviousDownloadUrl,
  }) async {
    try {
      final now = DateTime.now();
      final human = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = '${uid}_${human}_${now.millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref(
        '${AppConstants.profileImagesPath}/$uid/$fileName',
      );
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await task.ref.getDownloadURL();
      if (replacePreviousDownloadUrl != null &&
          replacePreviousDownloadUrl.isNotEmpty &&
          replacePreviousDownloadUrl != url) {
        await deleteFile(replacePreviousDownloadUrl);
      }
      return url;
    } on FirebaseException catch (e) {
      throw 'Failed to upload profile image: ${e.message}';
    }
  }

  /// Stores under `maintenance_images/{studentUid}/{requestId}_{yyyyMMdd_HHmmss}_{ms}_{i}.jpg`.
  /// Throws if any file fails so callers do not save a request with missing URLs.
  Future<List<String>> uploadMaintenanceImages(
    String studentUid,
    String requestId,
    List<File> files,
  ) async {
    if (files.isEmpty) return [];
    final urls = <String>[];
    final batch = DateTime.now();
    final human = DateFormat('yyyyMMdd_HHmmss').format(batch);
    final ms = batch.millisecondsSinceEpoch;
    for (var i = 0; i < files.length; i++) {
      final fileName = '${requestId}_${human}_${ms}_$i.jpg';
      final ref = _storage.ref(
        '${AppConstants.maintenanceImagesPath}/$studentUid/$fileName',
      );
      try {
        final task = await ref.putFile(
          files[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await task.ref.getDownloadURL());
      } on FirebaseException catch (e) {
        throw 'Failed to upload maintenance photo ${i + 1}: ${e.message}';
      }
    }
    return urls;
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // File may not exist — ignore
    }
  }
}