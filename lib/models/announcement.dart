import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String announcementId;
  final String title;
  final String body;
  final String sentBy;
  final String targetRole; // "all" | "student" | "staff"
  final DateTime createdAt;

  Announcement({
    required this.announcementId,
    required this.title,
    required this.body,
    required this.sentBy,
    this.targetRole = 'all',
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      announcementId: map['announcementId'] ?? '',
      title:          map['title'] ?? '',
      body:           map['body'] ?? '',
      sentBy:         map['sentBy'] ?? '',
      targetRole:     map['targetRole'] ?? 'all',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'announcementId': announcementId,
    'title':          title,
    'body':           body,
    'sentBy':         sentBy,
    'targetRole':     targetRole,
    'createdAt':      createdAt,
  };
}