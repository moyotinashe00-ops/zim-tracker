import 'package:cloud_firestore/cloud_firestore.dart';

class OutageReport {
  final String id;
  final String userId;
  final String zoneId;
  final DateTime timestamp;
  final String? comments;
  final String? imageUrl; // URL of uploaded image in Firebase Storage

  OutageReport({
    required this.id,
    required this.userId,
    required this.zoneId,
    required this.timestamp,
    this.comments,
    this.imageUrl,
  });

  factory OutageReport.fromFirestore(DocumentSnapshot doc) {
    return OutageReport.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory OutageReport.fromMap(String id, Map<String, dynamic> data) {
    return OutageReport(
      id: id,
      userId: data['userId'] ?? '',
      zoneId: data['zoneId'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      comments: data['comments'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'zoneId': zoneId,
      'timestamp': timestamp,
      'comments': comments,
      'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'zoneId': zoneId,
      'timestamp': Timestamp.fromDate(timestamp),
      'comments': comments,
      'imageUrl': imageUrl,
    };
  }
}
