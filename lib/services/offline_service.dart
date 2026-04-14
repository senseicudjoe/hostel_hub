import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import 'firestore_service.dart';

class OfflineService {
  // ── Initialise Hive boxes ─────────────────────────────────
  static Future<void> init() async {
    await Hive.openBox(AppConstants.pendingRequestsBox);
    await Hive.openBox(AppConstants.cacheBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  // ── Pending Maintenance Requests ──────────────────────────

  /// Save a request locally when the device is offline.
  Future<void> savePendingRequest(Map<String, dynamic> requestData) async {
    final box = Hive.box(AppConstants.pendingRequestsBox);
    await box.add(requestData);
  }

  /// Retrieve all locally saved requests.
  List<Map<String, dynamic>> getPendingRequests() {
    final box = Hive.box(AppConstants.pendingRequestsBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  int get pendingCount => Hive.box(AppConstants.pendingRequestsBox).length;

  bool get hasPendingRequests =>
      Hive.box(AppConstants.pendingRequestsBox).isNotEmpty;

  /// Clear all pending requests (called after successful sync).
  Future<void> clearPendingRequests() async {
    await Hive.box(AppConstants.pendingRequestsBox).clear();
  }

  // ── Flush to Firestore ────────────────────────────────────

  /// Submits every queued request to Firestore and clears the queue.
  /// Returns the number of requests successfully flushed.
  /// Silently skips individual items that fail (leaves queue intact for retry).
  Future<int> flush(FirestoreService firestoreService) async {
    final box = Hive.box(AppConstants.pendingRequestsBox);
    if (box.isEmpty) return 0;

    final entries = box.toMap(); // key → raw map
    final flushedKeys = <dynamic>[];

    for (final entry in entries.entries) {
      try {
        final data = Map<String, dynamic>.from(entry.value as Map);

        // Dates are stored as ISO strings — convert back to DateTime.
        if (data['createdAt'] is String) {
          data['createdAt'] = DateTime.parse(data['createdAt'] as String);
        }
        if (data['updatedAt'] is String) {
          data['updatedAt'] = DateTime.parse(data['updatedAt'] as String);
        }

        final request = _PendingRequestData.fromMap(data);
        await firestoreService.submitPendingRequest(request.toFirestoreMap());
        flushedKeys.add(entry.key);
      } catch (e) {
        debugPrint('OfflineService.flush: skipping key ${entry.key} — $e');
      }
    }

    // Remove only the successfully flushed entries.
    for (final key in flushedKeys) {
      await box.delete(key);
    }

    return flushedKeys.length;
  }

  // ── Generic Cache ─────────────────────────────────────────

  Future<void> cacheData(String key, dynamic value) async {
    final box = Hive.box(AppConstants.cacheBox);
    await box.put(key, value);
  }

  T? getCachedData<T>(String key) {
    final box = Hive.box(AppConstants.cacheBox);
    return box.get(key) as T?;
  }

  Future<void> clearCache() async {
    await Hive.box(AppConstants.cacheBox).clear();
  }
}

// ── Internal DTO ──────────────────────────────────────────────────────────────
// Keeps flush() independent of the MaintenanceRequest model import cycle.

class _PendingRequestData {
  final Map<String, dynamic> _raw;
  const _PendingRequestData._(this._raw);

  factory _PendingRequestData.fromMap(Map<String, dynamic> map) =>
      _PendingRequestData._(map);

  Map<String, dynamic> toFirestoreMap() => _raw;
}
