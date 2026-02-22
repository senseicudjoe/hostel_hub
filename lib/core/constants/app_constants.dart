class AppConstants {
  // Firestore collections
  static const String usersCollection              = 'users';
  static const String roomsCollection              = 'rooms';
  static const String allocationsCollection        = 'allocations';
  static const String maintenanceCollection        = 'maintenance_requests';
  static const String shuttleSchedulesCollection   = 'shuttle_schedules';
  static const String shuttleBookingsCollection    = 'shuttle_bookings';
  static const String announcementsCollection      = 'announcements';

  // User roles
  static const String roleStudent = 'student';
  static const String roleStaff   = 'staff';
  static const String roleAdmin   = 'admin';

  // Maintenance statuses
  static const String statusPending    = 'pending';
  static const String statusAssigned   = 'assigned';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved   = 'resolved';
  static const String statusCancelled  = 'cancelled';
  static const String statusConfirmed  = 'confirmed';

  // Room statuses
  static const String roomAvailable   = 'available';
  static const String roomOccupied    = 'occupied';
  static const String roomMaintenance = 'maintenance';

  // FCM topics
  static const String topicAll      = 'all';
  static const String topicStudents = 'students';
  static const String topicStaff    = 'staff';

  // Hive box names
  static const String pendingRequestsBox = 'pending_requests';
  static const String cacheBox           = 'cache';

  // Storage paths
  static const String profileImagesPath     = 'profile_images';
  static const String maintenanceImagesPath = 'maintenance_images';

  // Hostels
  static const List<String> hostels = [
    'Unity Hall',
    'Freedom Hall',
    'Independence Hall',
  ];

  // Shuttle pickup points
  static const List<String> shuttlePoints = [
    'Unity Hall',
    'Freedom Hall',
    'Independence Hall',
    'Main Academic Block',
  ];
}