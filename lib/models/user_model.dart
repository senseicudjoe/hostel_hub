import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "student" | "staff" | "admin"
  final String hostel;
  final String roomNumber;
  final String profileImageUrl;
  final String fcmToken;
  final DateTime createdAt;

  // ── Profile setup fields (collected during onboarding) ──────────────────
  final bool setupComplete;
  final String studentId;       // e.g. "AS/0123/24"
  final String phone;           // e.g. "+233 20 123 4567"
  final int yearOfStudy;        // 1–4, 0 = not set
  final String programme;       // e.g. "Computer Science"
  final String emergencyName;   // emergency contact full name
  final String emergencyPhone;  // emergency contact phone

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.hostel = '',
    this.roomNumber = '',
    this.profileImageUrl = '',
    this.fcmToken = '',
    required this.createdAt,
    this.setupComplete = false,
    this.studentId = '',
    this.phone = '',
    this.yearOfStudy = 0,
    this.programme = '',
    this.emergencyName = '',
    this.emergencyPhone = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid:             map['uid'] ?? '',
      name:            map['name'] ?? '',
      email:           map['email'] ?? '',
      role:            map['role'] ?? 'student',
      hostel:          map['hostel'] ?? '',
      roomNumber:      map['roomNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      fcmToken:        map['fcmToken'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      // If the field is absent this is a pre-existing account that predates the
      // setup flow — treat it as already complete so they aren't gated.
      // Only brand-new registrations have setupComplete explicitly set to false.
      setupComplete: map.containsKey('setupComplete')
          ? (map['setupComplete'] as bool? ?? false)
          : true,
      studentId:      map['studentId'] ?? '',
      phone:          map['phone'] ?? '',
      yearOfStudy:    (map['yearOfStudy'] as num?)?.toInt() ?? 0,
      programme:      map['programme'] ?? '',
      emergencyName:  map['emergencyName'] ?? '',
      emergencyPhone: map['emergencyPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'uid':             uid,
    'name':            name,
    'email':           email,
    'role':            role,
    'hostel':          hostel,
    'roomNumber':      roomNumber,
    'profileImageUrl': profileImageUrl,
    'fcmToken':        fcmToken,
    'createdAt':       createdAt,
    'setupComplete':   setupComplete,
    'studentId':       studentId,
    'phone':           phone,
    'yearOfStudy':     yearOfStudy,
    'programme':       programme,
    'emergencyName':   emergencyName,
    'emergencyPhone':  emergencyPhone,
  };

  UserModel copyWith({
    String? name,
    String? hostel,
    String? roomNumber,
    String? profileImageUrl,
    String? fcmToken,
    bool? setupComplete,
    String? studentId,
    String? phone,
    int? yearOfStudy,
    String? programme,
    String? emergencyName,
    String? emergencyPhone,
  }) {
    return UserModel(
      uid:             uid,
      name:            name ?? this.name,
      email:           email,
      role:            role,
      hostel:          hostel ?? this.hostel,
      roomNumber:      roomNumber ?? this.roomNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken:        fcmToken ?? this.fcmToken,
      createdAt:       createdAt,
      setupComplete:   setupComplete ?? this.setupComplete,
      studentId:       studentId ?? this.studentId,
      phone:           phone ?? this.phone,
      yearOfStudy:     yearOfStudy ?? this.yearOfStudy,
      programme:       programme ?? this.programme,
      emergencyName:   emergencyName ?? this.emergencyName,
      emergencyPhone:  emergencyPhone ?? this.emergencyPhone,
    );
  }
}
