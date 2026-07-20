import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAllData() async {
    await _seedZones();
    await _seedAlerts();
  }

  Future<void> _seedZones() async {
    final zones = [
      {
        'id': 'harare_central',
        'name': 'Harare Central',
        'region': 'Grid Zone A1',
        'status': 'OFF',
        'estimatedRestoration': DateTime.now().add(const Duration(hours: 2, minutes: 34)),
        'lastUpdated': DateTime.now(),
        'latitude': -17.8216,
        'longitude': 31.0492,
        'suburbCode': 'H1',
      },
      {
        'id': 'avondale',
        'name': 'Avondale',
        'region': 'Grid Zone B3',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -17.7865,
        'longitude': 31.0264,
        'suburbCode': 'H5',
      },
      {
        'id': 'borrowdale',
        'name': 'Borrowdale',
        'region': 'Grid Zone C2',
        'status': 'ON',
        'lastUpdated': DateTime.now(),
        'latitude': -17.7533,
        'longitude': 31.0968,
        'suburbCode': 'H12',
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
