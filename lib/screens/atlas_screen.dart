import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';
import 'package:zim_tracker/screens/info_screen.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> with SingleTickerProviderStateMixin {
  GridZone? _inspectedZone;
  String _aiSummary = 'Analyzing national grid telemetry...';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _generateAISummary();
  }

  void _generateAISummary() async {
    final model = context.read<HomeViewModel>();
    final zones = await model.allZonesStream.first;
    final summary = await model.getSummary(zones);
    if (mounted) {
      setState(() => _aiSummary = summary);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      body: Stack(
        children: [
          StreamBuilder<List<GridZone>>(
            stream: model.allZonesStream,
            builder: (context, snapshot) {
              final zones = snapshot.data ?? [];
              
              return FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(-18.8792, 29.8297),
                  initialZoom: 7.0,
                  onTap: (tapPosition, point) => setState(() => _inspectedZone = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zim_tracker.app',
                  ),
                  MarkerLayer(
                    markers: zones.map((zone) => Marker(
                      point: LatLng(zone.latitude, zone.longitude),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => setState(() => _inspectedZone = zone),
                        child: _buildPulsingMarker(zone),
                      ),
                    )).toList(),
                  ),
                ],
              );
            },
          ),
          
          // Overlay Header
          Positioned(
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
                        Icon(LucideIcons.map, color: VoltTheme.cyberBlue, size: 18),
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
                  onTap: () => model.performLiveSweep(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: VoltTheme.glassDecoration,
                    child: model.isSearching 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: VoltTheme.cyberBlue))
                      : Icon(LucideIcons.refreshCw, color: VoltTheme.cyberBlue, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InfoScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: VoltTheme.glassDecoration,
                    child: Icon(LucideIcons.bookOpen, color: VoltTheme.cyberBlue, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Intelligence Card
          Positioned(
            top: 130,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: VoltTheme.glassDecoration.copyWith(
                color: VoltTheme.obsidian.withValues(alpha: 0.9),
                border: Border.all(color: VoltTheme.cyberBlue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.sparkles, color: VoltTheme.amber, size: 14),
                      const SizedBox(width: 8),
                      Text('STRATEGIC SUMMARY', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.amber)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-SIMULATED ESTIMATE \u00b7 NOT LIVE ZETDC DATA',
                    style: VoltTheme.dataStyle.copyWith(fontSize: 7, color: VoltTheme.textDim),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiSummary,
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Live Ticker
          Positioned(
            bottom: _inspectedZone != null ? 240 : 30,
            left: 20,
            right: 20,
            child: StreamBuilder<List<OutageReport>>(
              stream: model.recentReportsStream,
              builder: (context, snapshot) {
                final reports = snapshot.data ?? [];
                if (reports.isEmpty) return const SizedBox.shrink();
                return Container(
                  height: 40,
                  decoration: VoltTheme.glassDecoration,
                  clipBehavior: Clip.antiAlias,
                  child: _MarqueeTicker(reports: reports),
                );
              },
            ),
          ),

          // Zone Inspector
          if (_inspectedZone != null) 
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: VoltTheme.glassDecoration.copyWith(
                  border: Border.all(color: (_inspectedZone!.status == PowerStatus.on ? VoltTheme.neonGreen : VoltTheme.neonRed).withValues(alpha: 0.2)),
                  color: VoltTheme.obsidian,
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
                            Text(_inspectedZone!.name.toUpperCase(), style: VoltTheme.dataStyle.copyWith(fontSize: 16, color: Colors.white)),
                            Text(_inspectedZone!.region, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => setState(() => _inspectedZone = null),
                          icon: Icon(LucideIcons.x, color: VoltTheme.textDim, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStat('STATUS', _inspectedZone!.status == PowerStatus.on ? 'ACTIVE' : 'OFFLINE', _inspectedZone!.status == PowerStatus.on ? VoltTheme.neonGreen : VoltTheme.neonRed),
                        const SizedBox(width: 32),
                        _buildStat('RESTORE', '18:00', Colors.white),
                        const Spacer(),
                        _buildConfidenceIndicator(_inspectedZone!),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          model.selectZone(_inspectedZone!.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Establishing primary link to ${_inspectedZone!.name}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VoltTheme.cyberBlue,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('ESTABLISH PRIMARY LINK', style: VoltTheme.dataStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPulsingMarker(GridZone zone) {
    final isPowerOn = zone.status == PowerStatus.on;
    final color = isPowerOn ? VoltTheme.neonGreen : VoltTheme.neonRed;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (!isPowerOn)
              Container(
                width: 30 * _pulseController.value,
                height: 30 * _pulseController.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2 * (1 - _pulseController.value)),
                ),
              ),
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
          ],
        );
      },
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

  Widget _buildConfidenceIndicator(GridZone zone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('CONFIDENCE', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) => Container(
            width: 4,
            height: 12,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: index < 4 ? VoltTheme.neonGreen : VoltTheme.textDim,
              borderRadius: BorderRadius.circular(1),
            ),
          )),
        ),
      ],
    );
  }
}

class _MarqueeTicker extends StatefulWidget {
  final List<OutageReport> reports;
  const _MarqueeTicker({required this.reports});

  @override
  State<_MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<_MarqueeTicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (_scrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            currentScroll + 50,
            duration: const Duration(seconds: 1),
            curve: Curves.linear,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.reports.map((r) => 'REPORT: ${r.comments?.toUpperCase() ?? "OUTAGE"} @ ${r.zoneId.toUpperCase()}').join('  •  ');
    
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              text,
              style: VoltTheme.dataStyle.copyWith(
                color: VoltTheme.cyberBlue,
                fontSize: 10,
              ),
            ),
          ),
        );
      },
    );
  }
}
