import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/services/firestore_service.dart';
import 'package:zim_tracker/models/grid_zone.dart';
import 'package:zim_tracker/models/outage_report.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _reportController = TextEditingController();
  String? _selectedZoneId;
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAILURE: COULD NOT INITIALIZE LINK')));
      }
    }
  }

  void _submitReport() async {
    if (_selectedZoneId == null || _reportController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('INPUT REQUIRED: SELECT ZONE & DESCRIBE')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        final uuid = Uuid();
        final ref = FirebaseStorage.instance
            .ref()
            .child('report_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}.jpg');

        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IMAGE UPLOAD FAILED: ${e.toString()}')));
        }
        return;
      }
    }

    final report = OutageReport(
      id: '',
      userId: user.uid,
      zoneId: _selectedZoneId!,
      timestamp: DateTime.now(),
      comments: _reportController.text,
      imageUrl: imageUrl,
    );

    await _firestoreService.reportOutage(report);

    if (mounted) {
      _reportController.clear();
      setState(() {
        _selectedImage = null;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('INTEL LOGGED: REPORT SUBMITTED FOR VERIFICATION')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR PICKING IMAGE: ${e.toString()}')));
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
              _buildStageGuide(),
              const SizedBox(height: 48),
              _buildReportingSection(),
              const SizedBox(height: 32),
              _buildTechnicalResources(),
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
          'KNOWLEDGE BASE',
          style: VoltTheme.dataStyle.copyWith(letterSpacing: 4, fontSize: 18, color: Colors.white),
        ),
        Text(
          'GRID SPECIFICATIONS & PROTOCOLS',
          style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: VoltTheme.cyberBlue),
        ),
      ],
    );
  }

  Widget _buildStageGuide() {
    return Column(
      children: [
        _buildStageItem(
          'STAGE 01',
          'STABLE MITIGATION',
          'Minimal impact. 2-4 hour daily cycles for residential areas. Industrial sector stable.',
          VoltTheme.neonGreen,
        ),
        _buildStageItem(
          'STAGE 02',
          'PEAK SHAVING',
          'Moderate impact. 6-hour rotations during morning and evening peak demand windows.',
          VoltTheme.amber,
        ),
        _buildStageItem(
          'STAGE 03',
          'GRID DEFICIT',
          'Heavy impact. 12-hour+ cycles. Only hospitals and essential services are prioritized.',
          VoltTheme.neonRed,
        ),
        _buildStageItem(
          'STAGE 04',
          'TOTAL COLLAPSE',
          'System failure risk. Indefinite unscheduled outages until regional generation recovers.',
          Colors.white,
          isCritical: true,
        ),
      ],
    );
  }

  Widget _buildStageItem(String stage, String title, String desc, Color color, {bool isCritical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: VoltTheme.glassDecoration.copyWith(
        border: Border(left: BorderSide(color: color, width: 2)),
        color: isCritical ? VoltTheme.neonRed.withValues(alpha: 0.1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stage, style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: color)),
              if (isCritical) Icon(LucideIcons.alertOctagon, color: VoltTheme.neonRed, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: VoltTheme.textMuted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildReportingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: VoltTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNITY INTELLIGENCE', style: VoltTheme.dataStyle.copyWith(fontSize: 12)),
          const SizedBox(height: 16),
          Text(
            'ZimTracker relies on user-reported telemetry. If your grid status differs from the official schedule, please flag it for verification.',
            style: TextStyle(color: VoltTheme.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildZonePicker(),
          const SizedBox(height: 12),
          TextField(
            controller: _reportController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: VoltTheme.voltInputDecoration(
              hintText: 'DESCRIBE OUTAGE...',
            ),
          ),
          const SizedBox(height: 20),

              // Image Preview and Controls
              if (_selectedImage != null || _isUploading) ...[
                SizedBox(height: 16),
                _isUploading
                    ? LinearProgressIndicator(
                        color: VoltTheme.neonRed,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: VoltTheme.overlay(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageButton(LucideIcons.camera, 'Take Photo', ImageSource.camera),
                    _buildImageButton(LucideIcons.image, 'Choose Photo', ImageSource.gallery),
                    if (_selectedImage != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: const Icon(LucideIcons.x, size: 16),
                        label: Text('REMOVE IMAGE', style: TextStyle(color: VoltTheme.textMuted, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoltTheme.neonRed.withValues(alpha: 0.1),
                  foregroundColor: VoltTheme.neonRed,
                  side: BorderSide(color: VoltTheme.neonRed, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VoltTheme.neonRed,
                        ),
                      )
                    : Text('LOG GRID FAILURE', style: VoltTheme.dataStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildReportIcon(LucideIcons.phone, 'Call ZETDC', () => _launch('tel:+263242700001')),
                const SizedBox(width: 12),
                _buildReportIcon(LucideIcons.messageSquare, 'Official Portal', () => _launch('https://selfservice.zetdc.co.zw/')),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildImageButton(IconData icon, String label, ImageSource source) {
    return ElevatedButton.icon(
      onPressed: () => _pickImage(source),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: VoltTheme.slate,
        foregroundColor: VoltTheme.textMain,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildZonePicker() {
    return StreamBuilder<List<GridZone>>(
      stream: _firestoreService.getGridZones(),
      builder: (context, snapshot) {
        final zones = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: VoltTheme.glassDecoration,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedZoneId,
              dropdownColor: VoltTheme.slate,
              hint: Text('SELECT GRID NODE', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textDim)),
              isExpanded: true,
              style: VoltTheme.dataStyle.copyWith(color: Colors.white, fontSize: 12),
              onChanged: (v) => setState(() => _selectedZoneId = v),
              items: zones.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name.toUpperCase()))).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportIcon(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: VoltTheme.overlay(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: VoltTheme.cyberBlue, size: 20),
              const SizedBox(height: 8),
              Text(label, style: VoltTheme.dataStyle.copyWith(fontSize: 8, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TECHNICAL RESOURCES', style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted)),
        const SizedBox(height: 16),
        _buildResourceTile('National Generation Statistics', LucideIcons.barChart3, 'https://www.zera.co.zw/'),
        _buildResourceTile('Regional Distribution Map', LucideIcons.map, 'https://zetdc.co.zw/'),
        _buildResourceTile('API Documentation for Devs', LucideIcons.code2, 'https://github.com/'),
      ],
    );
  }

  Widget _buildResourceTile(String title, IconData icon, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: VoltTheme.textDim, size: 18),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      trailing: Icon(LucideIcons.externalLink, size: 14, color: VoltTheme.textDim),
      onTap: () => _launch(url),
    );
  }
}
