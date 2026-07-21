import 'package:cloud_firestore/cloud_firestore.dart';

/// A structural grid node: real place, real (approximate) coordinates.
/// No status/restoration data lives here \u2014 that's populated afterwards by
/// [AIService.simulateNationalGrid], since we have no live ZETDC feed.
class _NodeDef {
  final String id;
  final String name;
  final String region; // Province / metro area
  final double lat;
  final double lng;
  final String suburbCode;
  const _NodeDef(this.id, this.name, this.region, this.lat, this.lng, this.suburbCode);
}

/// Populates Firestore with a national set of real Zimbabwean locations
/// spanning all 10 provinces, plus a rotation-group load-shedding schedule
/// per node. This is STRUCTURAL data only (geography + a plausible rotation
/// pattern) \u2014 it deliberately does NOT bake in fake live status, since that
/// would misrepresent simulated data as real. Call [AIService.simulateNationalGrid]
/// right after seeding to populate ON/OFF + ETA for every node in one pass.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Seeds structural zone data (geography only, placeholder status) and a
  /// rotation-group schedule for every node. Call [AIService.simulateNationalGrid]
  /// immediately after this to populate realistic ON/OFF status.
  Future<int> seedStructuralZones() async {
    final batch = _db.batch();

    for (final node in _nationalNodes) {
      final ref = _db.collection('zones').doc(node.id);
      batch.set(ref, {
        'name': node.name,
        'region': node.region,
        'status': 'ON', // Placeholder \u2014 overwritten by the AI sweep right after seeding.
        'estimatedRestoration': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'latitude': node.lat,
        'longitude': node.lng,
        'suburbCode': node.suburbCode,
      });
    }

    await batch.commit();

    for (final node in _nationalNodes) {
      await _seedRotationSchedule(node.id);
    }

    return _nationalNodes.length;
  }

  /// Assigns each node to one of 4 rotation groups (A-D) based on a stable
  /// hash of its id, then writes a weekly schedule mimicking real ZETDC-style
  /// rolling load shedding \u2014 weekday shedding blocks staggered by group,
  /// lighter shedding on weekends. This is an algorithmic simulation, not
  /// scraped from a real ZETDC notice.
  Future<void> _seedRotationSchedule(String zoneId) async {
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
        // Lighter shedding on weekends \u2014 shorter evening block only.
        slots = [
          {'startTime': '18:00', 'endTime': '21:00', 'type': 'OFF', 'title': 'Weekend Trim', 'subtitle': 'Reduced Rotation'},
          {'startTime': '21:00', 'endTime': '18:00', 'type': 'ON', 'title': 'Grid Stable', 'subtitle': 'Weekend Supply'},
        ];
      } else if (group == 3) {
        // Group D's block wraps midnight \u2014 split into two slots within the same day.
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
