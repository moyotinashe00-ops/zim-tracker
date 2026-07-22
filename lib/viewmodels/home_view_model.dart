import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:zim_tracker/repositories/grid_repository.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';
import 'package:zim_tracker/services/ai_service.dart';
import 'package:zim_tracker/services/live_grid_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeViewModel extends ChangeNotifier {
  final GridRepository _gridRepository = GridRepository();
  final AIService _aiService = AIService();
  final LiveGridService _liveGridService = LiveGridService();
  Timer? _refreshTimer;

  HomeViewModel() {
    _bootstrapLiveGrid();
    // Keep the grid current for as long as the app stays open, without
    // requiring the user to manually refresh or an admin to re-seed.
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) => _bootstrapLiveGrid());
  }

  Future<void> _bootstrapLiveGrid() async {
    try {
      await _liveGridService.ensureLiveGridData();
    } catch (e) {
      dev.log('VOLT: Live grid bootstrap/refresh failed', error: e);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  String _selectedZoneId = 'harare_central';
  String get selectedZoneId => _selectedZoneId;

  List<GridZone> _searchResults = [];
  List<GridZone> get searchResults => _searchResults;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  void selectZone(String zoneId) {
    _selectedZoneId = zoneId;
    _searchResults = [];
    notifyListeners();
  }

  Future<void> selectAndRegisterZone(GridZone zone) async {
    await _gridRepository.registerDynamicZone(zone);
    selectZone(zone.id);
    
    // Perform a live AI inference for this specific point
    final inferredStatus = await _aiService.inferStatusForCoordinate(zone.latitude, zone.longitude);
    await _gridRepository.updateZoneStatus(zone.id, inferredStatus);
  }

  Stream<GridZone> get currentZoneStream => _gridRepository.getZone(_selectedZoneId);
  Stream<List<OutageReport>> get reportsStream => _gridRepository.getAllReports();
  Stream<List<GridZone>> get allZonesStream => _gridRepository.getAllZones();
  Stream<List<OutageReport>> get recentReportsStream => _gridRepository.getAllReports().map((reports) => 
    reports.where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))).take(10).toList()
  );

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _gridRepository.searchZones(query);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> performLiveSweep() async {
    if (_isSearching) return; // Prevent overlapping requests
    _isSearching = true;
    notifyListeners();

    try {
      // forceRefresh: true bypasses the staleness check for an explicit,
      // user-triggered pull-to-refresh. This also handles first-run
      // geography population automatically if the registry is empty.
      await _liveGridService.ensureLiveGridData(forceRefresh: true);
    } catch (e) {
      dev.log('Live Sweep Error', error: e);
      // In a real app, we'd emit an error event or show a SnackBar via a GlobalKey
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> searchGlobal(String query) async {
    if (query.length < 3) return;
    _isSearching = true;
    notifyListeners();

    try {
      // Use Nominatim OSM Geocoder
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query, Zimbabwe&format=json&limit=5');
      final response = await http.get(url, headers: {'User-Agent': 'Volt_Zim_Tracker'});
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _searchResults = data.map((item) {
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);
          return GridZone(
            id: 'geo_${item['place_id']}',
            name: item['display_name'].split(',')[0],
            region: item['display_name'].split(',')[1].trim(),
            status: PowerStatus.on, // Default
            lastUpdated: DateTime.now(),
            latitude: lat,
            longitude: lon,
          );
        }).toList();
      }
    } catch (e) {
      dev.log('Global Search Error', error: e);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> quickUpdateStatus(PowerStatus status) async {
    await _gridRepository.updateZoneStatus(_selectedZoneId, status);
  }

  Future<String> getSummary(List<GridZone> zones) async {
    return await _aiService.getMapIntelligenceSummary(zones);
  }
}
