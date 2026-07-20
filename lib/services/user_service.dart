import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Stream<List<String>> getFavorites() {
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final List<dynamic> favs = doc.data()?['favorites'] ?? [];
      return favs.cast<String>();
    });
  }

  Future<void> toggleFavorite(String zoneId) async {
    if (uid == null) return;
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      await docRef.set({'favorites': [zoneId]});
    } else {
      final List<dynamic> favs = doc.data()?['favorites'] ?? [];
      if (favs.contains(zoneId)) {
        await docRef.update({
          'favorites': FieldValue.arrayRemove([zoneId])
        });
      } else {
        await docRef.update({
          'favorites': FieldValue.arrayUnion([zoneId])
        });
      }
    }
  }

  Stream<List<String>> getNotifications() {
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final List<dynamic> notes = doc.data()?['notifications'] ?? [];
      return notes.cast<String>();
    });
  }

  Future<void> toggleNotification(String zoneId) async {
    if (uid == null) return;
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      await docRef.set({'notifications': [zoneId]});
    } else {
      final List<dynamic> notes = doc.data()?['notifications'] ?? [];
      if (notes.contains(zoneId)) {
        await docRef.update({
          'notifications': FieldValue.arrayRemove([zoneId])
        });
      } else {
        await docRef.update({
          'notifications': FieldValue.arrayUnion([zoneId])
        });
      }
    }
  }

  Stream<Map<String, dynamic>> getPreferences() {
    if (uid == null) return Stream.value({});
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data() ?? {});
  }

  Future<void> updatePreference(String key, dynamic value) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({key: value}, SetOptions(merge: true));
  }
}
