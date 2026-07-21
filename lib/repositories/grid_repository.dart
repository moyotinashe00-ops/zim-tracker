import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';

class GridRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<GridZone> getZone(String zoneId) {
    return _firestore
        .collection('zones')
        .doc(zoneId)
        .snapshots()
        .map((doc) => GridZone.fromMap(doc.id, doc.data() ?? {}));
  }

  Future<List<GridZone>> searchZones(String query) async {
    final snapshot = await _firestore
        .collection('zones')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => GridZone.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> reportOutage(OutageReport report) async {
    await _firestore.collection('reports').add(report.toMap());
  }

  Stream<List<OutageReport>> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OutageReport.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateZoneStatus(String zoneId, PowerStatus status) async {
    await _firestore.collection('zones').doc(zoneId).update({
      'status': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> registerDynamicZone(GridZone zone) async {
    await _firestore.collection('zones').doc(zone.id).set(zone.toMap());
  }

  Future<void> wipeAllNodes() async {
    final snapshot = await _firestore.collection('zones').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<GridZone>> getAllZones() {
    return _firestore
        .collection('zones')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GridZone.fromMap(doc.id, doc.data()))
            .toList());
  }
}
