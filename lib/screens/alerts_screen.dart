import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/services/firestore_service.dart';
import 'package:zim_tracker/services/user_service.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/models/alert.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSubscriptionStatus(),
              const SizedBox(height: 32),
              _buildPulseHeader(),
              const SizedBox(height: 16),
              _buildPulseList(),
              const SizedBox(height: 32),
              _buildAdvancedMonitoring(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PULSE',
          style: VoltTheme.dataStyle.copyWith(letterSpacing: 4, fontSize: 18, color: Colors.white),
        ),
        Text(
          'NOTIFICATION INTELLIGENCE',
          style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.cyberBlue),
        ),
      ],
    );
  }

  Widget _buildSubscriptionStatus() {
    final userService = UserService();
    final vm = context.read<HomeViewModel>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.radio, color: VoltTheme.cyberBlue, size: 20),
                  const SizedBox(width: 12),
                  Text('NETWORK SUBSCRIPTIONS', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
                ],
              ),
              Icon(LucideIcons.moreHorizontal, color: VoltTheme.textDim, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<String>>(
            stream: userService.getNotifications(),
            builder: (context, snapshot) {
              final activeIds = snapshot.data ?? [];
              if (activeIds.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('NO ACTIVE SUBSCRIPTIONS', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textDim)),
                );
              }

              return StreamBuilder<List<GridZone>>(
                stream: _firestoreService.getZonesByIds(activeIds),
                builder: (context, zoneSnapshot) {
                  final zones = zoneSnapshot.data ?? [];
                  return Column(
                    children: zones.map((z) => _buildSubscriptionTile(z.name, true, () => userService.toggleNotification(z.id))).toList(),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showAddNodeModal(context, vm, userService),
            icon: Icon(LucideIcons.plus, size: 14, color: VoltTheme.cyberBlue),
            label: Text('ADD GRID NODE', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.cyberBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile(String area, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(area.toUpperCase(), style: VoltTheme.dataStyle.copyWith(fontSize: 12, color: Colors.white70)),
          Switch(
            value: active,
            onChanged: (v) => onTap(),
            activeTrackColor: VoltTheme.cyberBlue.withValues(alpha: 0.3),
            activeThumbColor: VoltTheme.cyberBlue,
          ),
        ],
      ),
    );
  }

  void _showAddNodeModal(BuildContext context, HomeViewModel vm, UserService userService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VoltTheme.slate,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DISCOVER GRID NODES', style: VoltTheme.dataStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              autofocus: true,
              style: VoltTheme.dataStyle.copyWith(color: Colors.white),
              onChanged: (v) => vm.searchGlobal(v),
              decoration: VoltTheme.voltInputDecoration(
                hintText: 'GLOBAL GRID DISCOVERY...',
                prefixIcon: LucideIcons.search,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, child) {
                  if (vm.isSearching) {
                    return Center(child: CircularProgressIndicator(color: VoltTheme.cyberBlue));
                  }
                  if (vm.searchResults.isEmpty) {
                    return Center(child: Text('ENTER ANY POINT IN ZIMBABWE', style: VoltTheme.dataStyle.copyWith(color: VoltTheme.textDim)));
                  }
                  return ListView.builder(
                    itemCount: vm.searchResults.length,
                    itemBuilder: (context, index) {
                      final zone = vm.searchResults[index];
                      return ListTile(
                        title: Text(zone.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(zone.region, style: TextStyle(color: VoltTheme.textMuted, fontSize: 10)),
                        trailing: Icon(LucideIcons.globe, color: VoltTheme.cyberBlue, size: 18),
                        onTap: () {
                          vm.selectAndRegisterZone(zone);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('GRID EVENTS', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
        Text('LAST 24H', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
      ],
    );
  }

  Widget _buildPulseList() {
    return StreamBuilder<List<GridAlert>>(
      stream: _firestoreService.getAlerts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: VoltTheme.cyberBlue));
        }

        final alerts = snapshot.data!;
        return Column(
          children: alerts.map((alert) => _buildPulseItem(alert)).toList(),
        );
      },
    );
  }

  Widget _buildPulseItem(GridAlert alert) {
    final color = _getAlertColor(alert.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: VoltTheme.glassDecoration.copyWith(
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getAlertIcon(alert.type), color: color, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(alert.zoneName.toUpperCase(), style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: Colors.white)),
                    Text(_formatTimestamp(alert.timestamp), style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textDim)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(alert.description, style: TextStyle(color: VoltTheme.textMuted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.unplanned: return VoltTheme.neonRed;
      case AlertType.maintenance: return VoltTheme.amber;
      case AlertType.stable: return VoltTheme.neonGreen;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.unplanned: return LucideIcons.alertTriangle;
      case AlertType.maintenance: return LucideIcons.wrench;
      case AlertType.stable: return LucideIcons.checkCircle2;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    if (diff.inHours < 24) return '${diff.inHours}H';
    return DateFormat('dd/MM').format(dt);
  }

  Widget _buildAdvancedMonitoring() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration.copyWith(
        color: VoltTheme.cyberBlue.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.activity, color: VoltTheme.cyberBlue, size: 24),
          const SizedBox(height: 16),
          Text('CRITICAL MONITORING', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            'Enable deep telemetry for substation fluctuations and phase monitoring in industrial zones.',
            textAlign: TextAlign.center,
            style: TextStyle(color: VoltTheme.textMuted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: VoltTheme.cyberBlue,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('INITIALIZE TELEMETRY', style: VoltTheme.dataStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
