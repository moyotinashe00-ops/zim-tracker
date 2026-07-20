import 'package:cloud_firestore/cloud_firestore.dart';

enum PowerStatus { on, off }

class GridZone {
  final String id;
  final String name;
  final String region;
  final PowerStatus status;
  final DateTime? estimatedRestoration;
  final DateTime lastUpdated;
  final double latitude;
  final double longitude;
  final String suburbCode; // ZETDC Suburb Code (e.g., H1, B12)

  GridZone({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    this.estimatedRestoration,
    required this.lastUpdated,
    this.latitude = -17.8216,
    this.longitude = 31.0492,
    this.suburbCode = '',
  });

  factory GridZone.fromFirestore(DocumentSnapshot doc) {
    return GridZone.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory GridZone.fromMap(String id, Map<String, dynamic> data) {
    return GridZone(
      id: id,
      name: data['name'] ?? '',
      region: data['region'] ?? '',
      status: data['status'] == 'on' || data['status'] == 'ON' ? PowerStatus.on : PowerStatus.off,
      estimatedRestoration: data['estimatedRestoration'] is Timestamp 
          ? (data['estimatedRestoration'] as Timestamp).toDate()
          : null,
      lastUpdated: data['lastUpdated'] is Timestamp 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : DateTime.now(),
      latitude: (data['latitude'] ?? -17.8216).toDouble(),
      longitude: (data['longitude'] ?? 31.0492).toDouble(),
      suburbCode: data['suburbCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'region': region,
      'status': status.name,
      'estimatedRestoration': estimatedRestoration,
      'lastUpdated': lastUpdated,
      'latitude': latitude,
      'longitude': longitude,
      'suburbCode': suburbCode,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'region': region,
      'status': status == PowerStatus.on ? 'ON' : 'OFF',
      'estimatedRestoration': estimatedRestoration != null ? Timestamp.fromDate(estimatedRestoration!) : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'latitude': latitude,
      'longitude': longitude,
      'suburbCode': suburbCode,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
