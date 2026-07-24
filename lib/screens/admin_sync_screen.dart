import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zim_tracker/services/ai_service.dart';
import 'package:zim_tracker/services/firestore_service.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/models/schedule_slot.dart';
import 'package:zim_tracker/services/live_grid_service.dart';

class AdminSyncScreen extends StatefulWidget {
  const AdminSyncScreen({super.key});

  @override
  State<AdminSyncScreen> createState() => _AdminSyncScreenState();
}

class _AdminSyncScreenState extends State<AdminSyncScreen> {
  final TextEditingController _noticeController = TextEditingController();
  final AIService _aiService = AIService();
  final FirestoreService _firestoreService = FirestoreService();
  final LiveGridService _liveGridService = LiveGridService();
  bool _isProcessing = false;
  bool _isSeeding = false;

  void _handleSync() async {
    if (_noticeController.text.isEmpty) return;

    setState(() => _isProcessing = true);
    final result = await _aiService.parseZetdcNotice(_noticeController.text);
    
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VoltTheme.neonRed,
            content: Text('PARSING ERROR: VERIFY GEMINI PROTOCOL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final List zonesData = result['zones'] ?? [];
      for (var z in zonesData) {
        final String name = z['name'];
        final List schedule = z['schedule'] ?? [];
        String zoneId = name.toLowerCase().replaceAll(' ', '_');
        
        for (var dayData in schedule) {
          final String day = dayData['day'];
          final List slotsData = dayData['slots'] ?? [];
          final List<ScheduleSlot> slots = slotsData.map((s) => ScheduleSlot.fromMap(s)).toList();
          await _firestoreService.updateZoneSchedule(zoneId, day, slots);
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: VoltTheme.slate,
            title: Text('SYNC SUCCESSFUL', style: VoltTheme.dataStyle.copyWith(color: VoltTheme.neonGreen)),
            content: Text(
              'Grid intelligence database updated with ${zonesData.length} suburban nodes.',
              style: TextStyle(color: VoltTheme.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('ACKNOWLEDGE', style: VoltTheme.dataStyle.copyWith(color: VoltTheme.cyberBlue)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DATABASE ERROR: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleForceRefresh() async {
    setState(() => _isSeeding = true);
    try {
      // Populates geography automatically if the registry is empty, and
      // always runs a fresh AI status sweep regardless of staleness. This
      // is the same automatic pipeline that runs on every app launch and
      // every 15 minutes in the background \u2014 this button just triggers it
      // on demand for testing, it doesn't do anything fundamentally
      // different from normal operation.
      await _liveGridService.ensureLiveGridData(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VoltTheme.neonGreen,
            content: Text(
              'LIVE GRID REFRESHED: AI SWEEP COMPLETE',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('REFRESH ERROR: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _handleWipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VoltTheme.slate,
        title: Text('WIPE REGISTRY?', style: VoltTheme.dataStyle.copyWith(color: VoltTheme.neonRed)),
        content: Text('This will decommission all nodes from the national grid database.', style: TextStyle(color: VoltTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DECOMMISSION', style: TextStyle(color: VoltTheme.neonRed))),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.wipeAllNodes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('REGISTRY WIPED: GRID DATABASE EMPTY')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      appBar: AppBar(
        backgroundColor: VoltTheme.obsidian,
        elevation: 0,
        title: Text('GRID SYNC PROTOCOL', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: VoltTheme.cyberBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INTEL INGESTION',
              style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'Paste Official\nGrid Notice',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, height: 1.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Ingest raw text from ZETDC communications. Gemini AI will structure the data for national distribution.',
              style: TextStyle(color: VoltTheme.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: VoltTheme.glassDecoration,
              child: TextField(
                controller: _noticeController,
                maxLines: 12,
                style: VoltTheme.dataStyle.copyWith(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'RAW DATA ENTRY...',
                  hintStyle: TextStyle(color: VoltTheme.textDim),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleSync,
                icon: _isProcessing 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(LucideIcons.sparkles, color: Colors.black),
                label: Text(
                  _isProcessing ? 'PROCESSING...' : 'INITIALIZE MAGIC SYNC',
                  style: VoltTheme.dataStyle.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoltTheme.cyberBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: VoltTheme.overlay(0.1)),
            const SizedBox(height: 24),
            Text(
              'LIVE GRID CONTROL',
              style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'The grid refreshes itself automatically on app launch and every 15 minutes. This button forces an immediate sweep for testing \u2014 it isn\'t required for normal operation.',
              style: TextStyle(color: VoltTheme.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isSeeding ? null : _handleForceRefresh,
                icon: _isSeeding 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.refreshCw),
                label: Text(_isSeeding ? 'REFRESHING GRID...' : 'FORCE REFRESH LIVE GRID'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VoltTheme.cyberBlue,
                  side: BorderSide(color: VoltTheme.cyberBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: _handleWipe,
                child: Text('DECOMMISSION ALL NODES', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.neonRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
