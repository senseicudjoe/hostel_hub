import 'package:cloud_firestore/cloud_firestore.dart';

class ShuttleBooking {
  final String bookingId;
  final String studentUid;
  final String scheduleId;
  final String pickupPoint;
  final String destination;
  final DateTime bookingTime;
  final String status; // "confirmed" | "cancelled"

  ShuttleBooking({
    required this.bookingId,
    required this.studentUid,
    required this.scheduleId,
    required this.pickupPoint,
    required this.destination,
    required this.bookingTime,
    this.status = 'confirmed',
  });

  factory ShuttleBooking.fromMap(Map<String, dynamic> map) {
    return ShuttleBooking(
      bookingId:   map['bookingId'] ?? '',
      studentUid:  map['studentUid'] ?? '',
      scheduleId:  map['scheduleId'] ?? '',
      pickupPoint: map['pickupPoint'] ?? '',
      destination: map['destination'] ?? '',
      bookingTime: map['bookingTime'] is Timestamp
          ? (map['bookingTime'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'confirmed',
    );
  }

  Map<String, dynamic> toMap() => {
    'bookingId':   bookingId,
    'studentUid':  studentUid,
    'scheduleId':  scheduleId,
    'pickupPoint': pickupPoint,
    'destination': destination,
    'bookingTime': bookingTime,
    'status':      status,
  };
}