import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String roomId;
  final String hostelName;
  final String roomNumber;
  final int floor;
  final int capacity;
  final int currentOccupants;
  final String status; // "available" | "occupied" | "maintenance"
  final String qrCode;

  RoomModel({
    required this.roomId,
    required this.hostelName,
    required this.roomNumber,
    required this.floor,
    required this.capacity,
    required this.currentOccupants,
    required this.status,
    required this.qrCode,
  });

  bool get isAvailable => status == 'available' && currentOccupants < capacity;

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId:           map['roomId'] ?? '',
      hostelName:       map['hostelName'] ?? '',
      roomNumber:       map['roomNumber'] ?? '',
      floor:            map['floor'] ?? 0,
      capacity:         map['capacity'] ?? 2,
      currentOccupants: map['currentOccupants'] ?? 0,
      status:           map['status'] ?? 'available',
      qrCode:           map['qrCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'roomId':           roomId,
    'hostelName':       hostelName,
    'roomNumber':       roomNumber,
    'floor':            floor,
    'capacity':         capacity,
    'currentOccupants': currentOccupants,
    'status':           status,
    'qrCode':           qrCode,
  };
}