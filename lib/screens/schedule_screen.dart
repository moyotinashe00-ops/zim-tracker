import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/services/firestore_service.dart';
import 'package:zim_tracker/models/schedule_slot.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _currentDay = 'MONDAY';
  final List<String> _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

  void _changeDay(bool next) {
    int currentIndex = _days.indexOf(_currentDay);
    setState(() {
      if (next) {
        _currentDay = _days[(currentIndex + 1) % _days.length];
      } else {
        _currentDay = _days[(currentIndex - 1 + _days.length) % _days.length];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildDaySelector(),
            Expanded(
              child: StreamBuilder<List<ScheduleSlot>>(
                stream: _firestoreService.getSchedule(vm.selectedZoneId, _currentDay),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: VoltTheme.cyberBlue));
                  }

                  final slots = snapshot.data ?? [];
                  if (slots.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: slots.length,
                    itemBuilder: (context, index) => _buildTimelineItem(slots[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHRONOS',
            style: VoltTheme.dataStyle.copyWith(letterSpacing: 4, fontSize: 18, color: Colors.white),
          ),
          Text(
            'TIMELINE INTELLIGENCE',
            style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.cyberBlue),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: VoltTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: VoltTheme.cyberBlue),
            onPressed: () => _changeDay(false),
          ),
          Text(
            _currentDay,
            style: VoltTheme.dataStyle.copyWith(fontSize: 16, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: VoltTheme.cyberBlue),
            onPressed: () => _changeDay(true),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ScheduleSlot slot) {
    final isOff = slot.type == SlotType.off;
    final color = isOff ? VoltTheme.neonRed : VoltTheme.neonGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: VoltTheme.glassDecoration.copyWith(
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${slot.startTime} — ${slot.endTime}',
                style: VoltTheme.dataStyle.copyWith(fontSize: 12, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                isOff ? 'PLANNED OUTAGE' : 'GRID ACTIVE',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              Text(
                isOff ? 'Stage 2 Load Shedding' : 'Stable Operational Capacity',
                style: const TextStyle(fontSize: 12, color: VoltTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),
          Icon(isOff ? LucideIcons.zapOff : LucideIcons.zap, color: color.withValues(alpha: 0.5), size: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.calendarX, color: VoltTheme.textDim, size: 48),
          const SizedBox(height: 16),
          Text(
            'NO DATA FOR THIS CYCLE',
            style: VoltTheme.dataStyle.copyWith(color: VoltTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
