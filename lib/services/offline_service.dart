import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class OfflineService {
  // ── Initialise Hive boxes ─────────────────────────────────
  static Future<void> init() async {
    await Hive.openBox(AppConstants.pendingRequestsBox);
    await Hive.openBox(AppConstants.cacheBox);
  }

  // ── Pending Maintenance Requests ──────────────────────────

  /// Save a request locally when the device is offline
  Future<void> savePendingRequest(Map<String, dynamic> requestData) async {
    final box = Hive.box(AppConstants.pendingRequestsBox);
    await box.add(requestData);
  }

  /// Retrieve all locally saved requests
  List<Map<String, dynamic>> getPendingRequests() {
    final box = Hive.box(AppConstants.pendingRequestsBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  bool get hasPendingRequests {
    return Hive.box(AppConstants.pendingRequestsBox).isNotEmpty;
  }

  /// Clear all pending requests (called after successful sync)
  Future<void> clearPendingRequests() async {
    await Hive.box(AppConstants.pendingRequestsBox).clear();
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