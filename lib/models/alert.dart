import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { unplanned, maintenance, stable }

class GridAlert {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final DateTime timestamp;
  final String zoneName;

  GridAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.zoneName,
  });

  factory GridAlert.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GridAlert(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: _parseType(data['type']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      zoneName: data['zoneName'] ?? '',
    );
  }

  static AlertType _parseType(String? type) {
    switch (type) {
      case 'UNPLANNED': return AlertType.unplanned;
      case 'MAINTENANCE': return AlertType.maintenance;
      case 'STABLE': return AlertType.stable;
      default: return AlertType.stable;
    }
  }
}
