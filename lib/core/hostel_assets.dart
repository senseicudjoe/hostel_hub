/// Bundled hero images for campus hostels (Explore grid).
///
/// Paths match files under [assets/hostels/]. Names must match
/// `AppConstants.hostels` / Firestore `hostelName` on rooms exactly.
abstract final class HostelAssets {
  HostelAssets._();

  static const String _dir = 'assets/hostels';

  /// Returns an asset path when we ship a curated cover; otherwise `null`
  /// so the UI can fall back to the first room photo URL from Firestore.
  static String? coverAssetPath(String hostelName) {
    switch (hostelName.trim()) {
      case 'Sutherland Hall':
        return '$_dir/sutherland_hall.jpeg';
      case 'Sisulu Hall':
        return '$_dir/sisulu_hall.jpeg';
      case 'Amu Hall':
        return '$_dir/amu_hall.jpeg';
      case 'Oteng Korankye II Hall':
        return '$_dir/oteng_korankye_ii_hall.jpeg';
      case 'Maathai Hall':
        return '$_dir/maathai_hall.jpeg';
      case 'Tawiah Hall':
        return '$_dir/tawiah_hall.jpeg';
      case 'Unity Hall':
        return '$_dir/unity_hall.jpeg';
      case 'Freedom Hall':
        return '$_dir/freedom_hall.jpeg';
      case 'Commonwealth Hall':
        return '$_dir/commonwealth_hall.jpeg';
      case 'Independence Hall':
        return '$_dir/independence_hall.jpeg';
      default:
        return null;
    }
  }
}
