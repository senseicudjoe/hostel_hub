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
  };

  UserModel copyWith({
    String? name,
    String? hostel,
    String? roomNumber,
    String? profileImageUrl,
    String? fcmToken,
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
    );
  }
}