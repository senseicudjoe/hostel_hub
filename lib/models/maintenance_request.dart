import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRequest {
  final String requestId;
  final String studentUid;
  final String roomId;
  final String title;
  final String description;
  final String category;
  final String roomNumber;
  final String hostelName;
  final List<String> imageUrls;
  final String status; // "pending" | "assigned" | "in_progress" | "resolved"
  final String assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRequest({
    required this.requestId,
    required this.studentUid,
    required this.roomId,
    required this.title,
    required this.description,
    this.category = 'General',
    this.roomNumber = '',
    this.hostelName = '',
    this.imageUrls = const [],
    this.status = 'pending',
    this.assignedTo = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceRequest.fromMap(Map<String, dynamic> map) {
    return MaintenanceRequest(
      requestId:   map['requestId'] ?? '',
      studentUid:  map['studentUid'] ?? '',
      roomId:      map['roomId'] ?? '',
      title:       map['title'] ?? '',
      description: map['description'] ?? '',
      category:    map['category'] ?? 'General',
      roomNumber:  map['roomNumber'] ?? '',
      hostelName:  map['hostelName'] ?? '',
      imageUrls:   List<String>.from(map['imageUrls'] ?? []),
      status:      map['status'] ?? 'pending',
      assignedTo:  map['assignedTo'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'requestId':   requestId,
    'studentUid':  studentUid,
    'roomId':      roomId,
    'title':       title,
    'description': description,
    'category':    category,
    'roomNumber':  roomNumber,
    'hostelName':  hostelName,
    'imageUrls':   imageUrls,
    'status':      status,
    'assignedTo':  assignedTo,
    'createdAt':   createdAt,
    'updatedAt':   updatedAt,
  };

  MaintenanceRequest copyWith({
    String? status,
    String? assignedTo,
    List<String>? imageUrls,
  }) {
    return MaintenanceRequest(
      requestId:   requestId,
      studentUid:  studentUid,
      roomId:      roomId,
      title:       title,
      description: description,
      category:    category,
      roomNumber:  roomNumber,
      hostelName:  hostelName,
      imageUrls:   imageUrls ?? this.imageUrls,
      status:      status ?? this.status,
      assignedTo:  assignedTo ?? this.assignedTo,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
    );
  }
}