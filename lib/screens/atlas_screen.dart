import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/screens/info_screen.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  GridZone? _inspectedZone;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      body: Stack(
        children: [
          StreamBuilder<List<GridZone>>(
            stream: vm.allZonesStream,
            builder: (context, snapshot) {
              final zones = snapshot.data ?? [];
              
              return FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(-18.8792, 29.8297), // Center of Zimbabwe
                  initialZoom: 7.0,
                  onTap: (_, __) => setState(() => _inspectedZone = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zim_tracker.app',
                  ),
                  MarkerLayer(
                    markers: zones.map((zone) => Marker(
                      point: LatLng(zone.latitude, zone.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => setState(() => _inspectedZone = zone),
                        child: _buildMapMarker(zone),
                      ),
                    )).toList(),
                  ),
                ],
              );
            },
          ),
          _buildOverlayHeader(),
          if (_inspectedZone != null) _buildZoneInspector(_inspectedZone!),
        ],
      ),
    );
  }

  Widget _buildMapMarker(GridZone zone) {
    final isPowerOn = zone.status == PowerStatus.on;
    final color = isPowerOn ? VoltTheme.neonGreen : VoltTheme.neonRed;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 4),
            ],
          ),
        ),
        if (!isPowerOn)
          const Icon(LucideIcons.zapOff, color: Colors.white, size: 8),
      ],
    );
  }

  Widget _buildOverlayHeader() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: VoltTheme.glassDecoration,
              child: Row(
                children: [
                  const Icon(LucideIcons.map, color: VoltTheme.cyberBlue, size: 18),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ATLAS', style: VoltTheme.dataStyle.copyWith(fontSize: 12, color: Colors.white)),
                      Text('NATIONAL GRID TELEMETRY', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.cyberBlue)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InfoScreen())),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: VoltTheme.glassDecoration,
              child: const Icon(LucideIcons.bookOpen, color: VoltTheme.cyberBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneInspector(GridZone zone) {
    final isPowerOn = zone.status == PowerStatus.on;
    final color = isPowerOn ? VoltTheme.neonGreen : VoltTheme.neonRed;

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: VoltTheme.glassDecoration.copyWith(
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name.toUpperCase(), style: VoltTheme.dataStyle.copyWith(fontSize: 16, color: Colors.white)),
                    Text(zone.region, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => _inspectedZone = null),
                  icon: const Icon(LucideIcons.x, color: VoltTheme.textDim, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStat('STATUS', isPowerOn ? 'ACTIVE' : 'OFFLINE', color),
                const SizedBox(width: 32),
                _buildStat('RESTORE', '18:00', Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  context.read<HomeViewModel>().selectZone(zone.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Focusing Dashboard on ${zone.name}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoltTheme.cyberBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('SET AS PRIMARY NODE', style: VoltTheme.dataStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: VoltTheme.dataStyle.copyWith(fontSize: 14, color: color)),
      ],
    );
  }
}
