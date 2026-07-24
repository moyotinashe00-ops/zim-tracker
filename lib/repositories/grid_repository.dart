import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';

class GridRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? get userId => _firebaseAuth.currentUser?.uid;

  Stream<GridZone> getZone(String zoneId) {
    return _firestore
        .collection('zones')
        .doc(zoneId)
        .snapshots()
        .map((doc) => GridZone.fromMap(doc.id, doc.data() ?? {}));
  }

  Future<List<GridZone>> searchZones(String query) async {
    // Search by name
    final nameSnapshot = await _firestore
        .collection('zones')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    // Search by region
    final regionSnapshot = await _firestore
        .collection('zones')
        .where('region', isGreaterThanOrEqualTo: query)
        .where('region', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    // Combine and deduplicate by zone id
    final Map<String, DocumentSnapshot> docs = {};
    for (var doc in nameSnapshot.docs) {
      docs[doc.id] = doc;
    }
    for (var doc in regionSnapshot.docs) {
      docs[doc.id] = doc;
    }

    return docs.values
        .map((doc) => GridZone.fromMap(doc.id, doc.data() as Map<String, dynamic>))
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

  /// Writes an AI-simulated status plus an optional restoration ETA in one
  /// update, so a zone that's OFF also shows when it's expected back.
  Future<void> updateZoneSimulation(String zoneId, PowerStatus status, int? etaMinutes) async {
    await _firestore.collection('zones').doc(zoneId).update({
      'status': status == PowerStatus.on ? 'ON' : 'OFF',
      'estimatedRestoration': etaMinutes != null
          ? Timestamp.fromDate(DateTime.now().add(Duration(minutes: etaMinutes)))
          : null,
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

  /// Records a user's vote on whether the AI-simulated status matched
  /// reality at their location. Uses a transaction to prevent vote spamming
  /// by checking for existing user votes in a subcollection.
  Future<void> voteZoneAccuracy(String zoneId, bool wasAccurate) async {
    final userId = this.userId;
    if (userId == null) {
      // User not signed in - fall back to basic increment (shouldn't happen in practice)
      await _firestore.collection('zones').doc(zoneId).update({
        wasAccurate ? 'accurateVotes' : 'inaccurateVotes': FieldValue.increment(1),
      });
      return;
    }

    final zoneDoc = _firestore.collection('zones').doc(zoneId);
    final userVoteDoc = zoneDoc.collection('votes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userVoteSnap = await transaction.get(userVoteDoc);
      final zoneSnap = await transaction.get(zoneDoc);

      if (!zoneSnap.exists) {
        throw Exception('Zone does not exist');
      }

      final currentData = zoneSnap.data() as Map<String, dynamic>;
      final currentAccurate = (currentData['accurateVotes'] ?? 0) as int;
      final currentInaccurate = (currentData['inaccurateVotes'] ?? 0) as int;

      if (userVoteSnap.exists) {
        // User has voted before - check if they're changing their vote
        final previousVote = (userVoteSnap.data() as Map<String, dynamic>)['vote'] as bool?;
        if (previousVote == wasAccurate) {
          // Same vote as before - no change needed
          return;
        } else {
          // Changed vote - adjust counters
          if (previousVote == true) {
                // Was accurate, now inaccurate
                transaction.update(zoneDoc, {
                  'accurateVotes': currentAccurate - 1,
                  'inaccurateVotes': currentInaccurate + 1,
                });
              } else {
                // Was inaccurate, now accurate
                transaction.update(zoneDoc, {
                  'accurateVotes': currentAccurate + 1,
                  'inaccurateVotes': currentInaccurate - 1,
                });
              }

          // Update the vote record
          transaction.update(userVoteDoc, {
            'vote': wasAccurate,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // New vote - create vote document and increment counter
        transaction.set(userVoteDoc, {
          'vote': wasAccurate,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (wasAccurate) {
          transaction.update(zoneDoc, {
            'accurateVotes': FieldValue.increment(1),
          });
        } else {
          transaction.update(zoneDoc, {
            'inaccurateVotes': FieldValue.increment(1),
          });
        }
      }
    });
  }

  /// Returns the most recent status-change events for a zone, newest first.
  /// Populated by [LiveGridService] whenever an AI sweep detects a zone's
  /// status actually flipped (not on every 15-minute poll -- only on
  /// change), so this reflects real transitions, not polling noise.
  Stream<List<Map<String, dynamic>>> getZoneHistory(String zoneId, {int limit = 20}) {
    return _firestore
        .collection('zones')
        .doc(zoneId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
