import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAllData() async {
    await _seedZones();
    await _seedAlerts();
  }

  Future<void> _seedZones() async {
    final zones = [
      // Harare Region
      {
        'id': 'harare_central',
        'name': 'Harare Central',
        'region': 'Harare',
        'status': 'OFF',
        'estimatedRestoration': DateTime.now().add(const Duration(hours: 2, minutes: 34)),
        'lastUpdated': DateTime.now(),
        'latitude': -17.8216,
        'longitude': 31.0492,
        'suburbCode': 'H1',
      },
      {
        'id': 'borrowdale',
        'name': 'Borrowdale',
        'region': 'Harare',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -17.7533,
        'longitude': 31.0968,
        'suburbCode': 'H12',
      },
      // Bulawayo Region
      {
        'id': 'bulawayo_central',
        'name': 'Bulawayo Central',
        'region': 'Bulawayo',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -20.1465,
        'longitude': 28.5833,
        'suburbCode': 'B1',
      },
      {
        'id': 'ascot',
        'name': 'Ascot',
        'region': 'Bulawayo',
        'status': 'OFF',
        'estimatedRestoration': DateTime.now().add(const Duration(hours: 4)),
        'lastUpdated': DateTime.now(),
        'latitude': -20.1750,
        'longitude': 28.6080,
        'suburbCode': 'B4',
      },
      // Mutare Region
      {
        'id': 'mutare_cbd',
        'name': 'Mutare CBD',
        'region': 'Manicaland',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -18.9702,
        'longitude': 32.6705,
        'suburbCode': 'M1',
      },
      // Gweru Region
      {
        'id': 'gweru_cbd',
        'name': 'Gweru CBD',
        'region': 'Midlands',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -19.4527,
        'longitude': 29.8191,
        'suburbCode': 'G1',
      },
      // Masvingo Region
      {
        'id': 'masvingo_cbd',
        'name': 'Masvingo CBD',
        'region': 'Masvingo',
        'status': 'OFF',
        'estimatedRestoration': DateTime.now().add(const Duration(hours: 1)),
        'lastUpdated': DateTime.now(),
        'latitude': -20.0637,
        'longitude': 30.8277,
        'suburbCode': 'MS1',
      },
      // Victoria Falls
      {
        'id': 'vic_falls',
        'name': 'Victoria Falls',
        'region': 'Matabeleland North',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -17.9243,
        'longitude': 25.8572,
        'suburbCode': 'VF1',
      },
      // Major Substations (The Spine)
      {
        'id': 'warren_sub',
        'name': 'Warren Substation',
        'region': 'Harare West',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -17.8518,
        'longitude': 30.8967,
        'suburbCode': 'W330',
      },
      {
        'id': 'marvel_sub',
        'name': 'Marvel Substation',
        'region': 'Bulawayo East',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -20.1251,
        'longitude': 28.6250,
        'suburbCode': 'M330',
      },
      {
        'id': 'insukamini_sub',
        'name': 'Insukamini Sub',
        'region': 'Midlands',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -19.3833,
        'longitude': 29.6000,
        'suburbCode': 'I400',
      },
      {
        'id': 'orange_grove',
        'name': 'Orange Grove',
        'region': 'Mutare',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -18.9707,
        'longitude': 32.6709,
        'suburbCode': 'OG132',
      },
      {
        'id': 'hwange_thermal',
        'name': 'Hwange Thermal',
        'region': 'Hwange',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -18.3831,
        'longitude': 26.4703,
        'suburbCode': 'HPS',
      },
    ];

    for (var z in zones) {
      final id = z['id'] as String;
      await _db.collection('zones').doc(id).set({
        'name': z['name'],
        'region': z['region'],
        'status': z['status'],
        'estimatedRestoration': z['estimatedRestoration'] != null 
            ? Timestamp.fromDate(z['estimatedRestoration'] as DateTime) 
            : null,
        'lastUpdated': Timestamp.fromDate(z['lastUpdated'] as DateTime),
        'latitude': z['latitude'],
        'longitude': z['longitude'],
        'suburbCode': z['suburbCode'],
      });

      // Seed schedules for each zone
      await _seedSchedules(id);
    }
  }

  Future<void> _seedSchedules(String zoneId) async {
    final days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    
    for (var day in days) {
      List<Map<String, dynamic>> slots = [];
      
      if (zoneId == 'harare_central') {
        slots = [
          {'startTime': '00:00', 'endTime': '04:00', 'type': 'OFF', 'title': 'Power Off', 'subtitle': 'Stage 2 Load Shedding'},
          {'startTime': '04:00', 'endTime': '12:00', 'type': 'ON', 'title': 'Grid Active', 'subtitle': 'Normal Supply'},
          {'startTime': '12:00', 'endTime': '18:00', 'type': 'OFF', 'title': 'Power Off', 'subtitle': 'Peak Management'},
          {'startTime': '18:00', 'endTime': '00:00', 'type': 'ON', 'title': 'Grid Active', 'subtitle': 'Stable Evening'},
        ];
      } else {
        slots = [
          {'startTime': '06:00', 'endTime': '10:00', 'type': 'OFF', 'title': 'Morning Cut', 'subtitle': 'Scheduled Rotation'},
          {'startTime': '10:00', 'endTime': '06:00', 'type': 'ON', 'title': 'Grid Stable', 'subtitle': 'No interruptions'},
        ];
      }

      await _db.collection('zones').doc(zoneId).collection('schedules').doc(day).set({
        'slots': slots,
      });
    }
  }

  Future<void> _seedAlerts() async {
    final alerts = [
      {
        'title': 'Emergency Maintenance',
        'description': 'Technical crews are repairing a faulty transformer. Restoration expected by 20:00.',
        'type': 'UNPLANNED',
        'zoneName': 'Bulawayo South',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
      },
      {
        'title': 'Grid Stabilization',
        'description': 'Routine maintenance concluded. Full power restored to the industrial area.',
        'type': 'STABLE',
        'zoneName': 'Gweru Industrial',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      },
      {
        'title': 'Scheduled Upgrade',
        'description': 'Upgrading substation capacity to handle higher winter loads.',
        'type': 'MAINTENANCE',
        'zoneName': 'Harare North',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      },
    ];

    for (var a in alerts) {
      await _db.collection('alerts').add({
        'title': a['title'],
        'description': a['description'],
        'type': a['type'],
        'zoneName': a['zoneName'],
        'timestamp': Timestamp.fromDate(a['timestamp'] as DateTime),
      });
    }
  }
}
