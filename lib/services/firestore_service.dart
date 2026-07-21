import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';
import 'package:zim_tracker/models/alert.dart';
import 'package:zim_tracker/models/schedule_slot.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<GridZone>> getGridZones() {
    return _db.collection('zones').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GridZone.fromFirestore(doc)).toList());
  }

  Stream<List<OutageReport>> getAllReports() {
    return _db.collection('reports').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OutageReport.fromFirestore(doc)).toList());
  }

  Stream<GridZone> getGridZone(String zoneId) {
    return _db.collection('zones').doc(zoneId).snapshots().map((doc) => GridZone.fromFirestore(doc));
  }

  Stream<List<GridZone>> getZonesByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    return _db
        .collection('zones')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GridZone.fromFirestore(doc)).toList());
  }

  Stream<List<GridAlert>> getAlerts() {
    return _db
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GridAlert.fromFirestore(doc)).toList());
  }

  Stream<List<ScheduleSlot>> getSchedule(String zoneId, String day) {
    return _db
        .collection('zones')
        .doc(zoneId)
        .collection('schedules')
        .doc(day.toUpperCase())
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return [];
          final List<dynamic> slots = doc.data()!['slots'] ?? [];
          return slots.map((s) => ScheduleSlot.fromMap(s as Map<String, dynamic>)).toList();
        });
  }

  Future<List<GridZone>> searchZones(String query) async {
    final snapshot = await _db
        .collection('zones')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(5)
        .get();
    return snapshot.docs.map((doc) => GridZone.fromFirestore(doc)).toList();
  }

  Future<void> reportOutage(OutageReport report) {
    return _db.collection('reports').add(report.toFirestore());
  }

  Future<void> updateZoneSchedule(String zoneId, String day, List<ScheduleSlot> slots) {
    return _db
        .collection('zones')
        .doc(zoneId)
        .collection('schedules')
        .doc(day.toUpperCase())
        .set({'slots': slots.map((s) => s.toMap()).toList()});
  }

  Future<void> updateZoneStatus(String zoneId, PowerStatus status) {
    return _db.collection('zones').doc(zoneId).update({
      'status': status == PowerStatus.on ? 'ON' : 'OFF',
      'lastUpdated': Timestamp.now(),
    });
  }

  Future<void> wipeAllNodes() async {
    final snapshot = await _db.collection('zones').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
