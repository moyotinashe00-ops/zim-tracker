import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/widgets/grid_pulse_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zim_tracker/screens/main_layout.dart';
import 'package:zim_tracker/services/user_service.dart';

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
                  color: Colors.white,
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
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analyzing nearby nodes...')),
                  );
                },
                icon: const Icon(LucideIcons.crosshair, color: VoltTheme.cyberBlue, size: 20),
              ),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(LucideIcons.logOut, color: VoltTheme.textMuted, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneHeader(BuildContext context, GridZone? zone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.mapPin, color: VoltTheme.cyberBlue, size: 14),
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
              const Icon(LucideIcons.zap, color: VoltTheme.textDim, size: 32),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat('RESTORATION', '2h 15m', LucideIcons.clock),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildStatusStat('CONFIDENCE', '88%', LucideIcons.shieldCheck),
            ],
          ),
        ],
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
              const Icon(LucideIcons.sparkles, color: VoltTheme.amber, size: 16),
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
      height: 200,
      width: double.infinity,
      decoration: VoltTheme.glassDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          StreamBuilder<List<GridZone>>(
            stream: vm.allZonesStream,
            builder: (context, snapshot) {
              final zones = snapshot.data ?? [];
              return FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-17.8216, 31.0492), // Default to Harare
                  initialZoom: 11.0,
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
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: (z.status == PowerStatus.on ? VoltTheme.neonGreen : VoltTheme.neonRed).withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              );
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

  Widget _buildQuickActions(BuildContext context, GridZone? zone) {
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
        _buildFavoriteToggle(context, zone),
      ],
    );
  }

  Widget _buildFavoriteToggle(BuildContext context, GridZone? zone) {
    if (zone == null) return const SizedBox.shrink();
    final userService = UserService();

    return StreamBuilder<List<String>>(
      stream: userService.getFavorites(),
      builder: (context, snapshot) {
        final isFav = snapshot.data?.contains(zone.id) ?? false;
        return _buildActionTile(
          icon: isFav ? LucideIcons.heart : LucideIcons.heart,
          title: isFav ? 'Remove from Watchlist' : 'Add to Watchlist',
          subtitle: isFav ? 'Tracking grid node actively' : 'Receive priority status updates',
          color: isFav ? VoltTheme.neonRed : VoltTheme.cyberBlue,
          onTap: () => userService.toggleFavorite(zone.id),
        );
      },
    );
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
          trailing: const Icon(LucideIcons.chevronRight, size: 16, color: VoltTheme.textDim),
        ),
      ),
    );
  }
}
