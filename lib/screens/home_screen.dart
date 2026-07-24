import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/theme/theme_controller.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/widgets/grid_pulse_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zim_tracker/screens/main_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: StreamBuilder<GridZone>(
                stream: vm.currentZoneStream,
                builder: (context, snapshot) {
                  final zone = snapshot.data;
                  return RefreshIndicator(
                    onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
                    color: VoltTheme.cyberBlue,
                    backgroundColor: VoltTheme.slate,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const GridPulseWidget(),
                          const SizedBox(height: 24),
                          _buildWatchlist(context, vm),
                          const SizedBox(height: 20),
                          _buildZoneHeader(context, zone),
                          const SizedBox(height: 20),
                          _buildMainStatusDisplay(context, zone),
                          const SizedBox(height: 20),
                          _buildAIForecast(context),
                          const SizedBox(height: 20),
                          _buildMiniAtlas(context, vm),
                          const SizedBox(height: 20),
                          _buildQuickActions(context, zone),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOLT',
                style: VoltTheme.dataStyle.copyWith(
                  letterSpacing: 4,
                  fontSize: 18,
                  color: VoltTheme.textMain,
                ),
              ),
              Text(
                'GRID INTELLIGENCE',
                style: VoltTheme.dataStyle.copyWith(
                  fontSize: 8,
                  color: VoltTheme.cyberBlue,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Builder(
                builder: (context) {
                  final themeController = context.watch<ThemeController>();
                  return IconButton(
                    onPressed: () => themeController.toggle(),
                    icon: Icon(
                      themeController.isDark ? LucideIcons.sun : LucideIcons.moon,
                      color: VoltTheme.cyberBlue,
                      size: 20,
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analyzing nearby nodes...')),
                  );
                },
                icon: Icon(LucideIcons.crosshair, color: VoltTheme.cyberBlue, size: 20),
              ),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: Icon(LucideIcons.logOut, color: VoltTheme.textMuted, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlist(BuildContext context, HomeViewModel vm) {
    return StreamBuilder<List<GridZone>>(
      stream: vm.watchlistZonesStream,
      builder: (context, snapshot) {
        final pinned = snapshot.data ?? [];
        if (pinned.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MY WATCHLIST', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted)),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pinned.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final z = pinned[index];
                  final isOn = z.status == PowerStatus.on;
                  final accent = isOn ? VoltTheme.neonGreen : VoltTheme.neonRed;
                  final isSelected = z.id == vm.selectedZoneId;

                  return GestureDetector(
                    onTap: () => vm.selectZone(z.id),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: VoltTheme.glassDecoration.copyWith(
                        border: Border.all(color: isSelected ? VoltTheme.cyberBlue : accent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => vm.togglePinnedZone(z.id),
                                child: Icon(LucideIcons.x, size: 14, color: VoltTheme.textDim),
                              ),
                            ],
                          ),
                          Text(
                            z.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isOn ? 'ON' : 'OFF',
                            style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: accent),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoneHeader(BuildContext context, GridZone? zone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.mapPin, color: VoltTheme.cyberBlue, size: 14),
            const SizedBox(width: 8),
            Text(
              zone?.region.toUpperCase() ?? 'REGION SELECT',
              style: VoltTheme.dataStyle.copyWith(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          zone?.name ?? 'Connecting...',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatusDisplay(BuildContext context, GridZone? zone) {
    final isPowerOn = zone?.status == PowerStatus.on;
    final accentColor = isPowerOn ? VoltTheme.neonGreen : VoltTheme.neonRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration.copyWith(
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STATUS',
                    style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isPowerOn ? 'GRID ACTIVE' : 'GRID OFFLINE',
                        style: VoltTheme.dataStyle.copyWith(
                          fontSize: 20,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(LucideIcons.zap, color: VoltTheme.textDim, size: 32),
            ],
          ),
          const SizedBox(height: 32),
          Divider(height: 1, color: VoltTheme.overlay(0.1)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat('RESTORATION', '2h 15m', LucideIcons.clock),
              Container(width: 1, height: 40, color: VoltTheme.overlay(0.1)),
              _buildStatusStat('CONFIDENCE', '88%', LucideIcons.shieldCheck),
            ],
          ),
          if (zone != null) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: VoltTheme.overlay(0.1)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  zone.accuracyPercent != null
                      ? 'WAS THIS ACCURATE? \u2022 ${zone.accuracyPercent!.toStringAsFixed(0)}% (${zone.totalVotes})'
                      : 'WAS THIS ACCURATE?',
                  style: VoltTheme.dataStyle.copyWith(fontSize: 9, color: VoltTheme.textMuted),
                ),
                Row(
                  children: [
                    _buildVoteButton(context, LucideIcons.thumbsUp, VoltTheme.neonGreen, () => _submitVote(context, zone.id, true)),
                    const SizedBox(width: 8),
                    _buildVoteButton(context, LucideIcons.thumbsDown, VoltTheme.neonRed, () => _submitVote(context, zone.id, false)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteButton(BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _submitVote(BuildContext context, String zoneId, bool wasAccurate) {
    context.read<HomeViewModel>().voteZoneAccuracy(zoneId, wasAccurate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: VoltTheme.slate,
        content: Text(
          'Thanks for the feedback',
          style: VoltTheme.dataStyle.copyWith(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatusStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: VoltTheme.textMuted, size: 16),
        const SizedBox(height: 8),
        Text(label, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: VoltTheme.dataStyle.copyWith(fontSize: 16, color: Colors.white)),
      ],
    );
  }

  Widget _buildAIForecast(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: VoltTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: VoltTheme.amber, size: 16),
              const SizedBox(width: 10),
              Text(
                'AI GRID FORECAST',
                style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on current generation patterns at Kariba South and imports from Eskom, stability is expected until 18:00.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAtlas(BuildContext context, HomeViewModel vm) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: VoltTheme.glassDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          StreamBuilder<List<GridZone>>(
            stream: vm.allZonesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return FutureBuilder<List<GridZone>>(
                  future: vm.getCachedZonesFallback(),
                  builder: (context, cacheSnapshot) {
                    return _buildMapContent(cacheSnapshot.data ?? [], isOffline: true);
                  },
                );
              }
              return _buildMapContent(snapshot.data ?? [], isOffline: false);
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [VoltTheme.obsidian.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('COMMUNITY RADAR', style: VoltTheme.dataStyle.copyWith(fontSize: 10)),
                GestureDetector(
                  onTap: () => MainLayout.of(context)?.setTab(4),
                  child: Text('OPEN ATLAS', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.cyberBlue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(List<GridZone> zones, {required bool isOffline}) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-18.8792, 29.8297), // Center of Zimbabwe for national view
            initialZoom: 6.0, // Zoomed out to show the whole country
            interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.zim_tracker.app',
            ),
            MarkerLayer(
              markers: zones.map((z) => Marker(
                point: LatLng(z.latitude, z.longitude),
                width: 15,
                height: 15,
                child: Container(
                  decoration: BoxDecoration(
                    color: (z.status == PowerStatus.on ? VoltTheme.neonGreen : VoltTheme.neonRed),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: (z.status == PowerStatus.on ? VoltTheme.neonGreen : VoltTheme.neonRed).withValues(alpha: 0.4),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        if (isOffline)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: VoltTheme.amber.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.wifiOff, size: 12, color: Colors.black),
                  const SizedBox(width: 6),
                  Text('OFFLINE \u2014 LAST KNOWN DATA', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: Colors.black)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, GridZone? zone) {
    final vm = context.read<HomeViewModel>();
    return Column(
      children: [
        _buildActionTile(
          icon: LucideIcons.alertTriangle,
          title: 'Report Outage',
          subtitle: 'Help update the community grid map',
          color: VoltTheme.neonRed,
          onTap: () => MainLayout.of(context)?.setTab(4), // Go to Info/Report tab
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: LucideIcons.calendar,
          title: 'View Timeline',
          subtitle: 'Scheduled maintenance for this week',
          color: VoltTheme.cyberBlue,
          onTap: () => MainLayout.of(context)?.setTab(1), // Go to Chronos tab
        ),
        const SizedBox(height: 12),
        if (zone != null) ...[
          _buildActionTile(
            icon: LucideIcons.history,
            title: 'Status History',
            subtitle: 'Recent ON/OFF transitions for this zone',
            color: VoltTheme.amber,
            onTap: () => _showHistorySheet(context, vm, zone),
          ),
          const SizedBox(height: 12),
        ],
        _buildFavoriteToggle(context, zone),
        if (zone != null) ...[
          const SizedBox(height: 12),
          _buildNotifyToggle(context, vm, zone),
        ],
      ],
    );
  }

  Widget _buildFavoriteToggle(BuildContext context, GridZone? zone) {
    if (zone == null) return const SizedBox.shrink();
    final vm = context.read<HomeViewModel>();

    return StreamBuilder<List<String>>(
      stream: vm.pinnedZoneIdsStream,
      builder: (context, snapshot) {
        final isFav = snapshot.data?.contains(zone.id) ?? false;
        return _buildActionTile(
          icon: LucideIcons.heart,
          title: isFav ? 'Remove from Watchlist' : 'Add to Watchlist',
          subtitle: isFav ? 'Tracking grid node actively' : 'Pin this zone for quick access',
          color: isFav ? VoltTheme.neonRed : VoltTheme.cyberBlue,
          onTap: () => vm.togglePinnedZone(zone.id),
        );
      },
    );
  }

  Widget _buildNotifyToggle(BuildContext context, HomeViewModel vm, GridZone zone) {
    return StreamBuilder<List<String>>(
      stream: vm.notifiedZoneIdsStream,
      builder: (context, snapshot) {
        final isSubscribed = snapshot.data?.contains(zone.id) ?? false;
        return _buildActionTile(
          icon: isSubscribed ? LucideIcons.bellRing : LucideIcons.bell,
          title: isSubscribed ? 'Alerts Enabled' : 'Notify Me On Change',
          subtitle: isSubscribed
              ? 'You\'ll get an alert when this zone flips'
              : 'Get notified when this zone\'s status changes',
          color: isSubscribed ? VoltTheme.neonGreen : VoltTheme.textMuted,
          onTap: () => vm.toggleZoneNotifications(zone.id),
        );
      },
    );
  }

  void _showHistorySheet(BuildContext context, HomeViewModel vm, GridZone zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VoltTheme.slate,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${zone.name.toUpperCase()} \u2014 STATUS HISTORY', style: VoltTheme.dataStyle.copyWith(fontSize: 12)),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: vm.getZoneHistory(zone.id),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];
                  if (!snapshot.hasData) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: VoltTheme.cyberBlue)),
                    );
                  }
                  if (history.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No transitions recorded yet \u2014 check back after the grid changes state a few times.',
                        style: TextStyle(color: VoltTheme.textMuted, fontSize: 13),
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: VoltTheme.overlay(0.1)),
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final isOn = entry['status'] == 'ON';
                        final ts = entry['timestamp'];
                        final time = ts is Timestamp ? ts.toDate() : null;
                        return ListTile(
                          leading: Icon(
                            isOn ? LucideIcons.zap : LucideIcons.zapOff,
                            color: isOn ? VoltTheme.neonGreen : VoltTheme.neonRed,
                            size: 18,
                          ),
                          title: Text(
                            isOn ? 'Power Restored' : 'Power Went Off',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          subtitle: time != null
                              ? Text(_formatRelativeTime(time), style: TextStyle(color: VoltTheme.textMuted, fontSize: 11))
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: VoltTheme.glassDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: Icon(LucideIcons.chevronRight, size: 16, color: VoltTheme.textDim),
        ),
      ),
    );
  }
}
