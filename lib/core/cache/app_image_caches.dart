import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk-backed image caches (separate from [DefaultCacheManager]) so profile
/// and maintenance photos keep longer-lived local copies and are not mixed
/// with generic network image eviction.
abstract final class AppImageCaches {
  static final CacheManager profile = CacheManager(
    Config(
      'hostel_hub_profile_images',
      stalePeriod: const Duration(days: 45),
      maxNrOfCacheObjects: 250,
    ),
  );

  static final CacheManager maintenance = CacheManager(
    Config(
      'hostel_hub_maintenance_images',
      stalePeriod: const Duration(days: 45),
      maxNrOfCacheObjects: 800,
    ),
  );
}
