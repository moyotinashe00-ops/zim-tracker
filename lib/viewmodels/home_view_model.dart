import 'package:flutter/material.dart';
import 'package:zim_tracker/repositories/grid_repository.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';

class HomeViewModel extends ChangeNotifier {
  final GridRepository _gridRepository = GridRepository();
  
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

  Stream<GridZone> get currentZoneStream => _gridRepository.getZone(_selectedZoneId);
  Stream<List<OutageReport>> get reportsStream => _gridRepository.getAllReports();
  Stream<List<GridZone>> get allZonesStream => _gridRepository.getAllZones();

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

  Future<void> quickUpdateStatus(PowerStatus status) async {
    await _gridRepository.updateZoneStatus(_selectedZoneId, status);
  }
}
