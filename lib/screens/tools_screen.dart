import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:torch_light/torch_light.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final Battery _battery = Battery();

  // Backup Power Calculator state
  String _backupMode = 'generator'; // 'generator' or 'inverter'
  final TextEditingController _tankLitersController = TextEditingController();
  final TextEditingController _consumptionLphController = TextEditingController();
  final TextEditingController _batteryAhController = TextEditingController();
  final TextEditingController _loadWattsController = TextEditingController();
  double? _backupRuntimeHours;
  
  double _calculatedUnits = 0.0;
  bool _isTorchOn = false;
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription? _batterySubscription;

  // Sample ZESA Tiered Pricing
  final List<Map<String, dynamic>> _tiers = [
    {'limit': 50.0, 'rate': 0.02},
    {'limit': 150.0, 'rate': 0.05},
    {'limit': 100.0, 'rate': 0.12},
    {'limit': double.infinity, 'rate': 0.20},
  ];

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  void _initBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });

    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) setState(() => _batteryState = state);
    });
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _amountController.dispose();
    _tankLitersController.dispose();
    _consumptionLphController.dispose();
    _batteryAhController.dispose();
    _loadWattsController.dispose();
    super.dispose();
  }

  void _calculateBackupRuntime() {
    if (_backupMode == 'generator') {
      final tank = double.tryParse(_tankLitersController.text) ?? 0.0;
      final consumption = double.tryParse(_consumptionLphController.text) ?? 0.0;
      setState(() => _backupRuntimeHours = consumption > 0 ? tank / consumption : null);
    } else {
      final ah = double.tryParse(_batteryAhController.text) ?? 0.0;
      final watts = double.tryParse(_loadWattsController.text) ?? 0.0;
      // Assumes a standard 12V battery bank and ~85% inverter efficiency
      // (typical for budget modified-sine inverters common locally).
      const voltage = 12.0;
      const efficiency = 0.85;
      setState(() => _backupRuntimeHours = watts > 0 ? (ah * voltage * efficiency) / watts : null);
    }
  }

  void _calculateUnits() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() => _calculatedUnits = 0.0);
      return;
    }

    double remainingAmount = amount;
    double totalUnits = 0.0;

    for (var tier in _tiers) {
      double tierLimit = tier['limit'];
      double tierRate = tier['rate'];
      double maxCostInTier = tierLimit * tierRate;

      if (remainingAmount >= maxCostInTier) {
        totalUnits += tierLimit;
        remainingAmount -= maxCostInTier;
      } else {
        totalUnits += remainingAmount / tierRate;
        remainingAmount = 0;
        break;
      }
    }
    setState(() => _calculatedUnits = totalUnits);
  }

  void _toggleTorch() async {
    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HARDWARE FAILURE: TORCH UNAVAILABLE')));
      }
    }
  }

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
              _buildSurvivalKit(),
              const SizedBox(height: 32),
              _buildCalculatorCard(),
              const SizedBox(height: 24),
              _buildBackupCalculatorCard(),
              const SizedBox(height: 24),
              _buildSolarEstimatorCard(),
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
          'UTILITY HUB',
          style: VoltTheme.dataStyle.copyWith(letterSpacing: 4, fontSize: 18, color: Colors.white),
        ),
        Text(
          'GRID SURVIVAL TOOLS',
          style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.cyberBlue),
        ),
      ],
    );
  }

  Widget _buildSurvivalKit() {
    final isCharging = _batteryState == BatteryState.charging;
    
    return Row(
      children: [
        Expanded(
          child: _buildKitTile(
            icon: _isTorchOn ? LucideIcons.lightbulb : LucideIcons.lightbulbOff,
            label: 'LIGHT SOURCE',
            value: _isTorchOn ? 'ACTIVE' : 'OFFLINE',
            color: _isTorchOn ? VoltTheme.amber : VoltTheme.textDim,
            onTap: _toggleTorch,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKitTile(
            icon: isCharging ? LucideIcons.batteryCharging : LucideIcons.batteryMedium,
            label: 'POWER RESERVE',
            value: '$_batteryLevel%',
            color: isCharging ? VoltTheme.neonGreen : (_batteryLevel < 20 ? VoltTheme.neonRed : VoltTheme.cyberBlue),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildKitTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: VoltTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(label, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: VoltTheme.dataStyle.copyWith(fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calculator, color: VoltTheme.cyberBlue, size: 20),
              const SizedBox(width: 12),
              Text('TOKEN CONVERSION', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          Text('CREDIT AMOUNT (USD)', style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: VoltTheme.dataStyle.copyWith(color: Colors.white, fontSize: 24),
            onChanged: (v) => _calculateUnits(),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: const TextStyle(color: VoltTheme.textDim),
              prefixIcon: const Icon(LucideIcons.dollarSign, color: VoltTheme.cyberBlue, size: 18),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ESTIMATED YIELD', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted)),
                Text(
                  '${_calculatedUnits.toStringAsFixed(1)} kWh',
                  style: VoltTheme.dataStyle.copyWith(color: VoltTheme.neonGreen, fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCalculatorCard() {
    final isGenerator = _backupMode == 'generator';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fuel, color: VoltTheme.cyberBlue, size: 20),
              const SizedBox(width: 12),
              Text('BACKUP POWER RUNTIME', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModeToggleButton('GENERATOR', isGenerator, () {
                  setState(() {
                    _backupMode = 'generator';
                    _backupRuntimeHours = null;
                  });
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeToggleButton('INVERTER/BATTERY', !isGenerator, () {
                  setState(() {
                    _backupMode = 'inverter';
                    _backupRuntimeHours = null;
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isGenerator) ...[
            _buildBackupField('FUEL TANK SIZE (LITRES)', _tankLitersController, LucideIcons.fuel),
            const SizedBox(height: 16),
            _buildBackupField('CONSUMPTION RATE (LITRES/HR)', _consumptionLphController, LucideIcons.gauge),
          ] else ...[
            _buildBackupField('BATTERY CAPACITY (Ah)', _batteryAhController, LucideIcons.batteryFull),
            const SizedBox(height: 16),
            _buildBackupField('LOAD DRAW (WATTS)', _loadWattsController, LucideIcons.plug),
            const SizedBox(height: 8),
            Text(
              'Assumes a standard 12V battery bank at ~85% inverter efficiency.',
              style: TextStyle(color: VoltTheme.textDim, fontSize: 11),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ESTIMATED RUNTIME', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted)),
                Text(
                  _backupRuntimeHours != null ? '${_backupRuntimeHours!.toStringAsFixed(1)} hrs' : '--',
                  style: VoltTheme.dataStyle.copyWith(color: VoltTheme.neonGreen, fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? VoltTheme.cyberBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? VoltTheme.cyberBlue : Colors.white10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: isActive ? VoltTheme.cyberBlue : VoltTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildBackupField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: VoltTheme.dataStyle.copyWith(color: Colors.white, fontSize: 18),
          onChanged: (v) => _calculateBackupRuntime(),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: VoltTheme.textDim),
            prefixIcon: Icon(icon, color: VoltTheme.cyberBlue, size: 16),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSolarEstimatorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration.copyWith(
        border: Border.all(color: VoltTheme.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sun, color: VoltTheme.amber, size: 20),
                  const SizedBox(width: 12),
                  Text('PHOTOVOLTAIC ROI', style: VoltTheme.dataStyle.copyWith(fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: VoltTheme.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('BETA', style: VoltTheme.dataStyle.copyWith(color: VoltTheme.amber, fontSize: 8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Calculate payback periods and energy independence forecasts for local solar installations.',
            style: TextStyle(color: VoltTheme.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('INITIALIZE SOLAR WIZARD', style: VoltTheme.dataStyle.copyWith(fontSize: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
