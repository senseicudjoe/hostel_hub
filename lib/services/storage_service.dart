import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<String?> uploadProfileImage(String uid, File file) async {
    try {
      final ref = _storage.ref(
        '${AppConstants.profileImagesPath}/$uid/profile.jpg',
      );
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw 'Failed to upload profile image: ${e.message}';
    }
  }

  Future<List<String>> uploadMaintenanceImages(
      String requestId,
      List<File> files,
      ) async {
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      try {
        final ref = _storage.ref(
          '${AppConstants.maintenanceImagesPath}/$requestId/image_$i.jpg',
        );
        final task = await ref.putFile(
          files[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await task.ref.getDownloadURL());
      } catch (_) {
        // Skip failed uploads silently
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