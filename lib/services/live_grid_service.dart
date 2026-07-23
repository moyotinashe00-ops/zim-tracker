import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/services/ai_service.dart';

/// A structural grid node: real place, real (approximate) coordinates.
/// No status/restoration data lives here -- that's populated by
/// [AIService.simulateNationalGrid] via [LiveGridService.ensureLiveGridData].
class _NodeDef {
  final String id;
  final String name;
  final String region; // Province / metro area
  final double lat;
  final double lng;
  final String suburbCode;
  const _NodeDef(this.id, this.name, this.region, this.lat, this.lng, this.suburbCode);
}

/// Keeps the national grid registry populated and current.
///
/// This replaces the old manual "admin seeds fake data" workflow. There are
/// two kinds of data here, handled differently:
///
/// 1. GEOGRAPHY (node id/name/region/coordinates/suburb code) -- this is
///    real-world structural data that doesn't change, so it stays as a
///    fixed list in code (AI cannot be trusted to invent accurate
///    real-world lat/lng for Zimbabwean towns -- it can hallucinate). It's
///    written to Firestore once, automatically, the first time the app
///    finds the `zones` collection empty. This is NOT "seed data" in the
///    problematic sense -- it's just where the pins live on the map.
///
/// 2. STATUS (ON/OFF + ETA) -- this is what's actually "live." It comes
///    from [AIService.simulateNationalGrid] and refreshes
///    automatically whenever it's stale (see [_staleAfter]), with no admin
///    action required. This is called from [HomeViewModel] on app start
///    and on a periodic timer, so every user sees the same synced,
///    current-ish simulated status without anyone needing to press a
///    button.
class LiveGridService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AIService _aiService = AIService();

  static const Duration _staleAfter = Duration(minutes: 15);

  static const List<_NodeDef> _nationalNodes = [
    // --- Harare Metro ---
    _NodeDef('harare_cbd', 'Harare CBD', 'Harare', -17.8292, 31.0522, 'H1'),
    _NodeDef('borrowdale', 'Borrowdale', 'Harare', -17.7533, 31.0968, 'H12'),
    _NodeDef('avondale', 'Avondale', 'Harare', -17.7987, 31.0313, 'H15'),
    _NodeDef('mbare', 'Mbare', 'Harare', -17.8579, 31.0119, 'H20'),
    _NodeDef('highfield', 'Highfield', 'Harare', -17.8747, 30.9945, 'H22'),
    _NodeDef('warren_park', 'Warren Park', 'Harare', -17.8310, 30.9757, 'H25'),
    _NodeDef('kuwadzana', 'Kuwadzana', 'Harare', -17.8264, 30.9257, 'H27'),
    _NodeDef('mount_pleasant', 'Mount Pleasant', 'Harare', -17.7692, 31.0431, 'H30'),
    _NodeDef('greendale', 'Greendale', 'Harare', -17.8103, 31.1122, 'H33'),
    _NodeDef('chitungwiza', 'Chitungwiza', 'Harare', -18.0127, 31.0756, 'H40'),
    _NodeDef('epworth', 'Epworth', 'Harare', -17.8944, 31.1478, 'H42'),
    _NodeDef('ruwa', 'Ruwa', 'Harare', -17.8901, 31.2461, 'H45'),
    _NodeDef('norton', 'Norton', 'Mashonaland West', -17.8814, 30.7016, 'H50'),
    _NodeDef('warren_sub', 'Warren Substation', 'Harare West', -17.8518, 30.8967, 'W330'),

    // --- Mashonaland West ---
    _NodeDef('chinhoyi', 'Chinhoyi', 'Mashonaland West', -17.3667, 30.2000, 'MW1'),
    _NodeDef('kadoma', 'Kadoma', 'Mashonaland West', -18.3333, 29.9167, 'MW5'),
    _NodeDef('chegutu', 'Chegutu', 'Mashonaland West', -18.1302, 30.1454, 'MW8'),
    _NodeDef('karoi', 'Karoi', 'Mashonaland West', -16.8151, 29.6939, 'MW12'),
    _NodeDef('kariba', 'Kariba', 'Mashonaland West', -16.5167, 28.8000, 'MW15'),

    // --- Mashonaland East ---
    _NodeDef('marondera', 'Marondera', 'Mashonaland East', -18.1853, 31.5519, 'ME1'),
    _NodeDef('murehwa', 'Murehwa', 'Mashonaland East', -17.6464, 31.7802, 'ME5'),
    _NodeDef('macheke', 'Macheke', 'Mashonaland East', -18.1667, 31.8500, 'ME8'),

    // --- Mashonaland Central ---
    _NodeDef('bindura', 'Bindura', 'Mashonaland Central', -17.3019, 31.3306, 'MC1'),
    _NodeDef('mount_darwin', 'Mount Darwin', 'Mashonaland Central', -16.7725, 31.5839, 'MC5'),
    _NodeDef('guruve', 'Guruve', 'Mashonaland Central', -16.6667, 30.7000, 'MC8'),

    // --- Manicaland ---
    _NodeDef('mutare_cbd', 'Mutare CBD', 'Manicaland', -18.9707, 32.6705, 'M1'),
    _NodeDef('orange_grove', 'Orange Grove', 'Manicaland', -18.9707, 32.6709, 'OG132'),
    _NodeDef('rusape', 'Rusape', 'Manicaland', -18.5333, 32.1167, 'M5'),
    _NodeDef('chipinge', 'Chipinge', 'Manicaland', -20.1883, 32.6222, 'M8'),
    _NodeDef('chimanimani', 'Chimanimani', 'Manicaland', -19.8000, 32.8667, 'M12'),

    // --- Midlands ---
    _NodeDef('gweru_cbd', 'Gweru CBD', 'Midlands', -19.4527, 29.8191, 'MD1'),
    _NodeDef('kwekwe', 'Kwekwe', 'Midlands', -18.9281, 29.8149, 'MD5'),
    _NodeDef('zvishavane', 'Zvishavane', 'Midlands', -20.3333, 30.0667, 'MD8'),
    _NodeDef('shurugwi', 'Shurugwi', 'Midlands', -19.6667, 30.0000, 'MD12'),
    _NodeDef('insukamini_sub', 'Insukamini Sub', 'Midlands', -19.3833, 29.6000, 'MD15'),

    // --- Masvingo ---
    _NodeDef('masvingo_cbd', 'Masvingo CBD', 'Masvingo', -20.0637, 30.8277, 'MS1'),
    _NodeDef('chiredzi', 'Chiredzi', 'Masvingo', -21.0500, 31.6667, 'MS5'),
    _NodeDef('triangle', 'Triangle', 'Masvingo', -21.0333, 31.4833, 'MS8'),

    // --- Matabeleland North ---
    _NodeDef('hwange', 'Hwange', 'Matabeleland North', -18.3639, 26.4736, 'N1'),
    _NodeDef('hwange_thermal', 'Hwange Thermal', 'Matabeleland North', -18.3831, 26.4703, 'HPS'),
    _NodeDef('vic_falls', 'Victoria Falls', 'Matabeleland North', -17.9243, 25.8572, 'N5'),
    _NodeDef('lupane', 'Lupane', 'Matabeleland North', -18.9333, 27.8000, 'N8'),

    // --- Matabeleland South ---
    _NodeDef('gwanda', 'Gwanda', 'Matabeleland South', -20.9333, 29.0000, 'S1'),
    _NodeDef('beitbridge', 'Beitbridge', 'Matabeleland South', -22.2167, 30.0000, 'S5'),
    _NodeDef('plumtree', 'Plumtree', 'Matabeleland South', -20.4833, 27.8167, 'S8'),

    // --- Bulawayo Metro ---
    _NodeDef('bulawayo_central', 'Bulawayo Central', 'Bulawayo', -20.1465, 28.5833, 'B1'),
    _NodeDef('ascot', 'Ascot', 'Bulawayo', -20.1750, 28.6080, 'B4'),
    _NodeDef('nkulumane', 'Nkulumane', 'Bulawayo', -20.1667, 28.5333, 'B8'),
    _NodeDef('hillside', 'Hillside', 'Bulawayo', -20.1833, 28.6167, 'B12'),
    _NodeDef('kumalo', 'Kumalo', 'Bulawayo', -20.1667, 28.6000, 'B15'),
    _NodeDef('marvel_sub', 'Marvel Substation', 'Bulawayo East', -20.1251, 28.6250, 'M330'),
  ];

  static const List<String> _days = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  /// The single entry point for keeping the grid current. Call this on app
  /// start and on a periodic timer -- it's cheap to call repeatedly since
  /// it checks staleness before doing any real work.
  ///
  /// - If `zones` is empty, writes geography + rotation schedules once.
  /// - If the last AI status sweep is older than [_staleAfter] (or
  ///   [forceRefresh] is true), runs a fresh AI sweep over every node and
  ///   writes status + ETA for all of them.
  Future<void> ensureLiveGridData({bool forceRefresh = false}) async {
    final zonesSnapshot = await _db.collection('zones').limit(1).get();
    if (zonesSnapshot.docs.isEmpty) {
      await _writeGeography();
    }

    final metaDoc = await _db.collection('meta').doc('gridStatus').get();
    final lastUpdated = (metaDoc.data()?['lastUpdated'] as Timestamp?)?.toDate();
    final isStale = lastUpdated == null || DateTime.now().difference(lastUpdated) > _staleAfter;

    if (forceRefresh || isStale) {
      await _refreshLiveStatus();
    }
  }

  Future<void> _writeGeography() async {
    final batch = _db.batch();

    for (final node in _nationalNodes) {
      final ref = _db.collection('zones').doc(node.id);
      batch.set(ref, {
        'name': node.name,
        'region': node.region,
        'status': 'ON', // Placeholder until the first AI sweep runs, seconds later.
        'estimatedRestoration': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'latitude': node.lat,
        'longitude': node.lng,
        'suburbCode': node.suburbCode,
      });
    }

    await batch.commit();

    for (final node in _nationalNodes) {
      await _writeRotationSchedule(node.id);
    }
  }

  /// Runs an AI sweep across every currently-registered zone and writes
  /// status + ETA for all of them in one batch, then stamps the refresh
  /// time so other clients/sessions know not to re-fetch immediately.
  Future<void> _refreshLiveStatus() async {
    final snapshot = await _db.collection('zones').get();
    if (snapshot.docs.isEmpty) return;

    final zoneRefs = {for (final doc in snapshot.docs) doc.id: doc.reference};
    final zones = snapshot.docs.map((doc) => GridZone.fromFirestore(doc)).toList();
    final previousStatus = {for (final z in zones) z.id: z.status};

    final results = await _aiService.simulateNationalGrid(zones);
    if (results.isEmpty) return; // AI unavailable this cycle -- try again next call.

    final batch = _db.batch();
    for (final entry in results.entries) {
      final ref = zoneRefs[entry.key];
      if (ref == null) continue;
      final newStatus = entry.value.status;

      batch.update(ref, {
        'status': newStatus == PowerStatus.on ? 'ON' : 'OFF',
        'estimatedRestoration': entry.value.etaMinutes != null
            ? Timestamp.fromDate(DateTime.now().add(Duration(minutes: entry.value.etaMinutes!)))
            : null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Only log a history entry on an actual transition, not on every
      // 15-minute poll -- otherwise the history view would just be 96
      // identical entries a day instead of a meaningful uptime record.
      if (previousStatus[entry.key] != null && previousStatus[entry.key] != newStatus) {
        final historyRef = ref.collection('history').doc();
        batch.set(historyRef, {
          'status': newStatus == PowerStatus.on ? 'ON' : 'OFF',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.set(_db.collection('meta').doc('gridStatus'), {'lastUpdated': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  /// Assigns each node to one of 4 rotation groups (A-D) based on a stable
  /// hash of its id, then writes a weekly schedule mimicking real
  /// ZETDC-style rolling load shedding -- weekday shedding blocks staggered
  /// by group, lighter shedding on weekends. This is an algorithmic
  /// simulation, not scraped from a real ZETDC notice.
  Future<void> _writeRotationSchedule(String zoneId) async {
    final group = zoneId.hashCode.abs() % 4; // 0=A, 1=B, 2=C, 3=D
    final weekdayOffBlock = [
      {'start': '04:00', 'end': '10:00'}, // Group A
      {'start': '10:00', 'end': '16:00'}, // Group B
      {'start': '16:00', 'end': '22:00'}, // Group C
      {'start': '22:00', 'end': '04:00'}, // Group D (wraps past midnight, handled as two slots below)
    ][group];

    for (final day in _days) {
      final isWeekend = day == 'SATURDAY' || day == 'SUNDAY';
      List<Map<String, dynamic>> slots;

      if (isWeekend) {
        // Lighter shedding on weekends -- shorter evening block only.
        slots = [
          {'startTime': '18:00', 'endTime': '21:00', 'type': 'OFF', 'title': 'Weekend Trim', 'subtitle': 'Reduced Rotation'},
          {'startTime': '21:00', 'endTime': '18:00', 'type': 'ON', 'title': 'Grid Stable', 'subtitle': 'Weekend Supply'},
        ];
      } else if (group == 3) {
        // Group D's block wraps midnight -- split into two slots within the same day.
        slots = [
          {'startTime': '00:00', 'endTime': '04:00', 'type': 'OFF', 'title': 'Power Off', 'subtitle': 'Group D Rotation'},
          {'startTime': '04:00', 'endTime': '22:00', 'type': 'ON', 'title': 'Grid Active', 'subtitle': 'Normal Supply'},
          {'startTime': '22:00', 'endTime': '00:00', 'type': 'OFF', 'title': 'Power Off', 'subtitle': 'Group D Rotation'},
        ];
      } else {
        slots = [
          {'startTime': '00:00', 'endTime': weekdayOffBlock['start']!, 'type': 'ON', 'title': 'Grid Active', 'subtitle': 'Normal Supply'},
          {'startTime': weekdayOffBlock['start']!, 'endTime': weekdayOffBlock['end']!, 'type': 'OFF', 'title': 'Power Off', 'subtitle': 'Group ${String.fromCharCode(65 + group)} Rotation'},
          {'startTime': weekdayOffBlock['end']!, 'endTime': '00:00', 'type': 'ON', 'title': 'Grid Active', 'subtitle': 'Stable Evening'},
        ];
      }

      await _db.collection('zones').doc(zoneId).collection('schedules').doc(day).set({'slots': slots});
    }
  }
}
