import 'dart:convert';
import 'dart:developer' as dev;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:zim_tracker/models/grid_zone.dart';

/// Simulated status for a single zone, produced by [AIService.simulateNationalGrid].
class SimulatedZoneStatus {
  final PowerStatus status;
  final int? etaMinutes; // Minutes until restoration, only meaningful when status == off.
  SimulatedZoneStatus(this.status, this.etaMinutes);
}

/// Client-side Volt AI service.
///
/// DELIBERATE, TEMPORARY DESIGN: this calls Gemini directly from the device
/// instead of through the Cloud Functions backend in /functions. That
/// backend is fully written and ready to go \u2014 it's on hold only because
/// enabling it requires upgrading the Firebase project to the Blaze plan.
///
/// The API key below is injected at build time via --dart-define-from-file
/// (see gemini_config.json.example at the repo root) and is NEVER committed
/// to source control. For this to be safe-ish, the key MUST be restricted
/// in Google Cloud Console (APIs & Services > Credentials) to:
///   1. API restriction: "Generative Language API" only.
///   2. Application restriction: Android apps, scoped to this app's
///      package name + release SHA-1 signing fingerprint (and/or iOS
///      bundle ID for the iOS build).
/// Even restricted, a determined attacker can extract the key from a
/// compiled APK/IPA and use it from an app with the same signing cert on
/// the same device class \u2014 restrictions reduce blast radius, they don't
/// eliminate it. Set a daily quota on the key too. Move this logic back
/// into functions/index.js once Blaze is enabled; the client-facing method
/// signatures here are intentionally identical to that version so the
/// swap is a find-and-replace of this file, nothing else.
///
/// FREE-TIER KEY NOTE: since April 2026, Google's free API tier only
/// covers Flash-class models — Pro-series models (e.g. gemini-3.1-pro)
/// are paid-only now. All tiers below are Flash-class so a free key works
/// end to end. Free tier is also rate-limited (roughly 10-15 requests per
/// minute, ~1,500 per day for Flash as of mid-2026 — check the live figures
/// for your project in AI Studio, Google adjusts these). One
/// simulateNationalGrid() call covers all 48 zones in a single request, so
/// normal usage of this app stays well within that. Avoid adding a loop
/// that calls inferStatusForCoordinate() per-zone instead — that would
/// burn through the per-minute quota fast.
class AIService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Flash-class only — required for free-tier API keys (Pro models are
  // paid-only as of April 2026).
  final List<String> _modelTiers = [
    'gemini-3.5-flash',
    'gemini-3.1-flash',
    'gemini-3.1-flash-lite',
  ];

  int _currentModelIndex = 0;
  late GenerativeModel _activeModel;

  AIService() {
    if (_apiKey.isEmpty) {
      dev.log(
        'VOLT AI: No GEMINI_API_KEY supplied at build time. '
        'Run with --dart-define-from-file=gemini_config.json. AI features will no-op.',
      );
    }
    _initActiveModel();
  }

  void _initActiveModel() {
    _activeModel = GenerativeModel(
      model: _modelTiers[_currentModelIndex],
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  bool _fallbackToNextModel() {
    if (_currentModelIndex + 1 < _modelTiers.length) {
      _currentModelIndex++;
      dev.log('VOLT AI: Model unavailable/failing. Falling back to "${_modelTiers[_currentModelIndex]}".');
      _initActiveModel();
      return true;
    }
    return false;
  }

  /// Ingests raw ZETDC notice text and returns a structured JSON map.
  Future<Map<String, dynamic>?> parseZetdcNotice(String text) async {
    if (_apiKey.isEmpty) return null;
    final prompt = '''
    Return ONLY a JSON object representing the ZETDC load shedding notice.
    DO NOT include conversational text or markdown.

    Schema:
    {
      "zones": [
        {
          "name": "Suburb Name",
          "suburbCode": "Code",
          "schedule": [
            {"day": "MONDAY", "slots": [{"startTime": "06:00", "endTime": "10:00", "type": "OFF"}]}
          ]
        }
      ]
    }

    Notice Text:
    $text
    ''';

    return await _executeWithResilience((model) => _generateAndParse([Content.text(prompt)], model));
  }

  /// Generates a predictive forecast for grid stability.
  Future<String> getGridForecast(double generation, double demand, String stage) async {
    if (_apiKey.isEmpty) return 'AI unavailable \u2014 no key configured for this build.';
    final prompt =
        'Given current generation of ${generation}MW against a demand of ${demand}MW at Stage $stage, '
        'provide a 1-sentence grid stability forecast for a Zimbabwean user. This is a simulation, not live official data.';

    return await _executeWithResilience((model) async {
          final response = await model.generateContent([Content.text(prompt)]);
          return response.text ?? 'Stability expected to remain consistent with current schedule.';
        }) ??
        'Forecast telemetry currently unavailable.';
  }

  /// Provides a strategic overview of the national grid status.
  Future<String> getMapIntelligenceSummary(List<GridZone> zones) async {
    if (_apiKey.isEmpty) return 'AI unavailable \u2014 no key configured for this build.';
    final offZones = zones.where((z) => z.status == PowerStatus.off).map((z) => z.name).join(', ');
    final prompt =
        'Analyze these Zimbabwean suburbs currently simulated as without power: $offZones. '
        'Provide a 1-sentence strategic summary of the simulated national grid health and where the '
        'primary deficits are concentrated. Do not claim this is live official ZETDC data.';

    return await _executeWithResilience((model) async {
          final response = await model.generateContent([Content.text(prompt)]);
          return response.text ?? 'Grid stability holding across most nodes.';
        }) ??
        'National grid intelligence currently normalizing.';
  }

  /// Simulates ON/OFF status (and, if OFF, an ETA in minutes) for every
  /// node in a single call, so the whole country populates consistently
  /// in one pass instead of one request per zone.
  Future<Map<String, SimulatedZoneStatus>> simulateNationalGrid(List<GridZone> zones) async {
    if (_apiKey.isEmpty || zones.isEmpty) return {};

    final nodeInfo = zones.map((z) => 'ID: ${z.id}, Name: ${z.name}, Region: ${z.region}').join('\n');
    final prompt = '''
    Current Zimbabwe Time: ${DateTime.now().toIso8601String()}.
    You are SIMULATING a realistic Zimbabwean power grid status (ZETDC-style rotational
    load shedding under a generation deficit), for demo purposes. This is not live data.
    Roughly 30-45% of nodes should be OFF at any given time, distributed unevenly \u2014 don't
    make it perfectly uniform, cluster some outages by region as a real deficit would.

    Nodes:
    $nodeInfo

    For each node return its status and, if OFF, an estimated minutes-until-restoration
    between 30 and 360.

    Return ONLY JSON in this exact format:
    {"nodes": [{"id": "node_id_from_list", "status": "ON", "etaMinutes": 0}]}
    ''';

    final data = await _executeWithResilience((model) => _generateAndParse([Content.text(prompt)], model));
    if (data == null) return {};

    final List nodes = data['nodes'] ?? [];
    final validIds = zones.map((z) => z.id).toSet();

    Map<String, SimulatedZoneStatus> results = {};
    for (var n in nodes) {
      final id = n['id']?.toString();
      if (id == null || !validIds.contains(id)) continue;
      final status = n['status'] == 'ON' ? PowerStatus.on : PowerStatus.off;
      final eta = status == PowerStatus.off ? (n['etaMinutes'] as num?)?.toInt() : null;
      results[id] = SimulatedZoneStatus(status, eta);
    }
    return results;
  }

  /// Infers power status for a specific coordinate based on nearby regional data.
  Future<PowerStatus> inferStatusForCoordinate(double lat, double lng) async {
    if (_apiKey.isEmpty) return PowerStatus.on;
    final prompt =
        'Given a specific location in Zimbabwe at coordinates ($lat, $lng), simulate whether it is '
        'currently LIKELY to have power given typical load shedding patterns. Return ONLY "ON" or "OFF".';

    final result = await _executeWithResilience((model) async {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() == 'ON' ? PowerStatus.on : PowerStatus.off;
    });
    return result ?? PowerStatus.on;
  }

  /// Resilient execution wrapper with tiered model fallback.
  Future<T?> _executeWithResilience<T>(Future<T?> Function(GenerativeModel model) action, {int depth = 0}) async {
    if (depth > _modelTiers.length) {
      dev.log('VOLT AI: Maximum resilience depth reached. Aborting request.');
      return null;
    }

    try {
      final result = await action(_activeModel);
      if (result == null) {
        dev.log('VOLT AI: Action returned null on model "${_modelTiers[_currentModelIndex]}". Attempting fallback.');
        if (_fallbackToNextModel()) {
          return await _executeWithResilience(action, depth: depth + 1);
        }
      }
      return result;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      dev.log('VOLT AI Service Exception [Model: ${_modelTiers[_currentModelIndex]}]: $e');

      if (errorStr.contains('503') ||
          errorStr.contains('unavailable') ||
          errorStr.contains('busy') ||
          errorStr.contains('high demand') ||
          errorStr.contains('quota') ||
          errorStr.contains('429') ||
          errorStr.contains('limit') ||
          errorStr.contains('exhausted') ||
          errorStr.contains('not found') ||
          errorStr.contains('not supported')) {
        if (_fallbackToNextModel()) {
          return await _executeWithResilience(action, depth: depth + 1);
        }
      }

      dev.log('VOLT AI: Terminal failure for this request logic path.', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _generateAndParse(List<Content> content, GenerativeModel model) async {
    final response = await model.generateContent(content);
    return _extractAndParseJson(response.text);
  }

  Map<String, dynamic>? _extractAndParseJson(String? text) {
    if (text == null) return null;

    String sanitized = text.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      int start = sanitized.indexOf('{');
      if (start == -1) return null;

      int end = _findClosingBrace(sanitized, start);
      if (end == -1) {
        end = sanitized.lastIndexOf('}');
      }

      if (end != -1 && end > start) {
        sanitized = sanitized.substring(start, end + 1);
      }

      return jsonDecode(sanitized) as Map<String, dynamic>;
    } catch (e) {
      dev.log('JSON Extraction/Parse Error: $e');
      dev.log('Raw text attempt: $text');
      return null;
    }
  }

  int _findClosingBrace(String text, int start) {
    int count = 0;
    for (int i = start; i < text.length; i++) {
      if (text[i] == '{') count++;
      if (text[i] == '}') {
        count--;
        if (count == 0) return i;
      }
    }
    return -1;
  }
}
