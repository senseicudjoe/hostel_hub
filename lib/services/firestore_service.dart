import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_request.dart';
import '../models/announcement.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── USERS ─────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((s) => s.exists ? UserModel.fromMap(s.data()!) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  Stream<List<UserModel>> getAllStudents() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleStudent)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  Stream<List<UserModel>> getAllStaff() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleStaff)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  // ── ROOMS ─────────────────────────────────────────────────

  Stream<List<RoomModel>> getRooms() {
    return _db
        .collection(AppConstants.roomsCollection)
        .orderBy('hostelName')
        .snapshots()
        .map((s) => s.docs.map((d) => RoomModel.fromMap(d.data())).toList());
  }

  Stream<List<RoomModel>> getAvailableRooms() {
    return _db
        .collection(AppConstants.roomsCollection)
        .where('status', isEqualTo: AppConstants.roomAvailable)
        .snapshots()
        .map((s) => s.docs.map((d) => RoomModel.fromMap(d.data())).toList());
  }

  Future<RoomModel?> getRoomByQrCode(String qrCode) async {
    final snap = await _db
        .collection(AppConstants.roomsCollection)
        .where('qrCode', isEqualTo: qrCode)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return RoomModel.fromMap(snap.docs.first.data());
    return null;
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    await _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .update({'status': status});
  }

  /// Live updates when the room document changes (occupancy, status, etc.).
  Stream<RoomModel?> watchRoom(String roomId) {
    return _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .snapshots()
        .map((s) {
      if (!s.exists || s.data() == null) return null;
      final m = Map<String, dynamic>.from(s.data()!);
      m['roomId'] = (m['roomId'] as String?)?.isNotEmpty == true
          ? m['roomId']
          : s.id;
      return RoomModel.fromMap(m);
    });
  }

  /// Resolves the student's active allocation → room document stream.
  Stream<RoomModel?> watchStudentRoom(String studentUid) {
    return _db
        .collection(AppConstants.allocationsCollection)
        .where('studentUid', isEqualTo: studentUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .asyncExpand((snap) {
      if (snap.docs.isEmpty) return Stream<RoomModel?>.value(null);
      final roomId = snap.docs.first.data()['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        return Stream<RoomModel?>.value(null);
      }
      return watchRoom(roomId);
    });
  }

  // ── ALLOCATIONS ───────────────────────────────────────────

  Future<Map<String, dynamic>?> getStudentAllocation(String studentUid) async {
    final snap = await _db
        .collection(AppConstants.allocationsCollection)
        .where('studentUid', isEqualTo: studentUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return snap.docs.first.data();
    return null;
  }

  Stream<List<Map<String, dynamic>>> getAllAllocations() {
    return _db
        .collection(AppConstants.allocationsCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> allocateRoom({
    required String studentUid,
    required String roomId,
    required String hostelName,
    required String roomNumber,
    required int capacity,
    required int currentOccupants,
  }) async {
    final id = 'alloc_${_uuid.v4().substring(0, 8)}';
    final batch = _db.batch();

    // Create allocation
    batch.set(_db.collection(AppConstants.allocationsCollection).doc(id), {
      'allocationId': id,
      'studentUid':   studentUid,
      'roomId':       roomId,
      'hostelName':   hostelName,
      'roomNumber':   roomNumber,
      'allocatedAt':  FieldValue.serverTimestamp(),
      'status':       'active',
    });

    // Update room — only mark as occupied when the room is actually full
    final newOccupants = currentOccupants + 1;
    final newStatus = newOccupants >= capacity
        ? AppConstants.roomOccupied
        : AppConstants.roomAvailable;
    batch.update(_db.collection(AppConstants.roomsCollection).doc(roomId), {
      'currentOccupants': FieldValue.increment(1),
      'status':           newStatus,
    });

    // Update student profile
    batch.update(_db.collection(AppConstants.usersCollection).doc(studentUid), {
      'hostel':     hostelName,
      'roomNumber': roomNumber,
    });

    await batch.commit();
  }

  Future<void> deallocateRoom(String allocationId, String studentUid, String roomId) async {
    final batch = _db.batch();

    batch.update(
      _db.collection(AppConstants.allocationsCollection).doc(allocationId),
      {'status': 'expired'},
    );
    batch.update(
      _db.collection(AppConstants.roomsCollection).doc(roomId),
      {'currentOccupants': FieldValue.increment(-1)},
    );
    batch.update(
      _db.collection(AppConstants.usersCollection).doc(studentUid),
      {'hostel': '', 'roomNumber': ''},
    );

    await batch.commit();
  }

  // ── MAINTENANCE REQUESTS ──────────────────────────────────

  Future<String> submitMaintenanceRequest(MaintenanceRequest request) async {
    await _db
        .collection(AppConstants.maintenanceCollection)
        .doc(request.requestId)
        .set(request.toMap());
    return request.requestId;
  }

  Stream<List<MaintenanceRequest>> getStudentMaintenanceRequests(String studentUid) {
    // Note: Avoiding `.orderBy('createdAt')` here removes the need for a composite
    // index (studentUid + createdAt). We sort client-side instead.
    return _db
        .collection(AppConstants.maintenanceCollection)
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => MaintenanceRequest.fromMap(d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<MaintenanceRequest>> getAllMaintenanceRequests() {
    return _db
        .collection(AppConstants.maintenanceCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MaintenanceRequest.fromMap(d.data())).toList());
  }

  Stream<List<MaintenanceRequest>> getMaintenanceByStatus(String status) {
    return _db
        .collection(AppConstants.maintenanceCollection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => MaintenanceRequest.fromMap(d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<MaintenanceRequest?> watchMaintenanceRequest(String requestId) {
    return _db
        .collection(AppConstants.maintenanceCollection)
        .doc(requestId)
        .snapshots()
        .map((s) {
      if (!s.exists || s.data() == null) return null;
      return MaintenanceRequest.fromMap(s.data()!);
    });
  }

  Future<void> updateMaintenanceStatus({
    required String requestId,
    required String status,
    String assignedTo = '',
  }) async {
    await _db.collection(AppConstants.maintenanceCollection).doc(requestId).update({
      'status':     status,
      'assignedTo': assignedTo,
      'updatedAt':  FieldValue.serverTimestamp(),
    });
  }

  // ── ANNOUNCEMENTS ─────────────────────────────────────────

  Stream<List<Announcement>> getAnnouncements(String role) {
    return _db
        .collection(AppConstants.announcementsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Announcement.fromMap(d.data()))
            .where((a) {
              if (role == AppConstants.roleAdmin) return true;
              return a.targetRole == 'all' || a.targetRole == role;
            })
            .toList());
  }

  Future<void> postAnnouncement(Announcement announcement) async {
    await _db
        .collection(AppConstants.announcementsCollection)
        .doc(announcement.announcementId)
        .set(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _db
        .collection(AppConstants.announcementsCollection)
        .doc(announcementId)
        .delete();
  }
}