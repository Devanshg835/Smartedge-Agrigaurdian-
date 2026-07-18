import 'dart:convert';
import 'package:flutter/services.dart';

/// LocalKbService — Standalone Knowledge Base service for Flutter.
/// Loads and indexes assets/knowledge_base.json so the mobile app can perform
/// disease lookups, action plan retrieval, and Hindi advisory generation 100% offline
/// without expecting an active Arduino UNO Q server connection.
class LocalKbService {
  static final Map<String, Map<String, dynamic>> _index = {};
  static bool _isLoaded = false;

  /// Loads and indexes assets/knowledge_base.json
  static Future<void> init() async {
    if (_isLoaded) return;

    try {
      final jsonStr = await rootBundle.loadString("assets/knowledge_base.json");
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<dynamic> diseases = data["diseases"] ?? [];

      for (final item in diseases) {
        if (item is Map<String, dynamic>) {
          final id = (item["id"] ?? "").toString().toLowerCase();
          final name = (item["name"] ?? "").toString().toLowerCase();
          final disease = (item["disease"] ?? "").toString().toLowerCase();

          if (id.isNotEmpty) _index[id] = item;
          if (name.isNotEmpty) _index[name] = item;
          if (disease.isNotEmpty) _index[disease] = item;
        }
      }
      _isLoaded = true;
    } catch (e) {
      // Ignore or log error
    }
  }

  /// Retrieves matching disease object (including action_plan) for a class label
  static Future<Map<String, dynamic>?> getDisease(String query) async {
    await init();
    if (query.trim().isEmpty) return null;

    final qClean = query.trim().toLowerCase();

    // 1. Direct match
    if (_index.containsKey(qClean)) return _index[qClean];

    // 2. Substring match
    for (final entry in _index.entries) {
      if (qClean.contains(entry.key) || entry.key.contains(qClean)) {
        return entry.value;
      }
    }

    // 3. Normalized underscore match
    final qNorm = qClean.replaceAll("___", "_").replaceAll("__", "_");
    for (final entry in _index.entries) {
      final keyNorm = entry.key.replaceAll("___", "_").replaceAll("__", "_");
      if (qNorm.contains(keyNorm) || keyNorm.contains(qNorm)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Generates a complete Hindi advisory directly from local Knowledge Base object
  static String generateHindiAdvisory({
    required Map<String, dynamic> diseaseInfo,
    required double confidence,
    Map<String, dynamic>? sensorData,
  }) {
    final crop = diseaseInfo["crop"] ?? "फसल";
    final disease = diseaseInfo["disease"] ?? "बीमारी";
    final severity = diseaseInfo["severity"] ?? "Medium";
    final actionPlan = diseaseInfo["action_plan"] as Map<String, dynamic>? ?? {};

    final today = List<String>.from(actionPlan["today"] ?? ["प्रभावित पत्तियां हटाएं"]);
    final organic = List<String>.from(diseaseInfo["organic_treatment"] ?? ["नीम ऑयल का छिड़काव करें"]);
    final chemical = List<String>.from(diseaseInfo["chemical_treatment"] ?? ["कॉपर ऑक्सीक्लोराइड का उपयोग करें"]);
    final next3Days = List<String>.from(actionPlan["next_3_days"] ?? ["पत्तियों को सूखा रखें"]);
    final recovery = actionPlan["expected_recovery"] ?? "10-14 Days";

    final lines = <String>[];
    lines.add("🌿 **फसल बीमारी**: $crop - $disease");
    lines.add("📊 **सटीकता (Confidence)**: ${(confidence * 100).toStringAsFixed(1)}%");
    lines.add("⚠️ **गंभीरता (Severity)**: $severity\n");

    lines.add("📋 **आज का मुख्य कार्य (Today's Action):**");
    for (final item in today) {
      lines.add("  • $item");
    }

    lines.add("\n🌱 **जैविक उपचार (Organic Treatment):**");
    for (final item in organic) {
      lines.add("  • $item");
    }

    lines.add("\n🧪 **रासायनिक उपचार (Chemical Treatment):**");
    for (final item in chemical) {
      lines.add("  • $item");
    }

    lines.add("\n⏳ **अगले 3 दिनों की योजना:**");
    for (final item in next3Days) {
      lines.add("  • $item");
    }

    lines.add("\n🔄 **अनुमानित सुधार समय**: $recovery");

    if (sensorData != null && sensorData.containsKey("soil_moisture")) {
      final double moisture = (sensorData["soil_moisture"] as num).toDouble();
      if (moisture < 30) {
        lines.add("\n💧 **सिंचाई सलाह**: मिट्टी में नमी कम है (${moisture.toStringAsFixed(1)}%)। आज हल्की सिंचाई करें।");
      } else if (moisture > 80) {
        lines.add("\n🚫 **सिंचाई सलाह**: मिट्टी में अत्यधिक नमी है (${moisture.toStringAsFixed(1)}%)। सिंचाई रोकें।");
      }
    }

    return lines.join("\n");
  }
}
