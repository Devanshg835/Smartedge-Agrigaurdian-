import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// HistoryService — Local storage for disease scans & analytics calculations
class HistoryService {
  static const String _storageKey = "agri_scan_history_v1";

  /// Saves a new disease scan to local history
  static Future<void> addScanRecord({
    required String diseaseName,
    required double confidence,
    required Map<String, dynamic> actionPlan,
    Map<String, dynamic>? sensorData,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_storageKey) ?? [];

    final now = DateTime.now();
    final record = {
      "id": now.millisecondsSinceEpoch.toString(),
      "disease_name": diseaseName,
      "confidence": confidence,
      "timestamp": "${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      "month": "${_getMonthName(now.month)} ${now.year}",
      "action_plan": actionPlan,
      "sensor_data": sensorData ?? {},
      "image_path": imagePath ?? "",
      "is_healthy": diseaseName.toLowerCase().contains("healthy"),
    };

    rawList.insert(0, jsonEncode(record)); // Newest first

    // Keep up to 100 historical records
    if (rawList.length > 100) {
      rawList.removeLast();
    }

    await prefs.setStringList(_storageKey, rawList);
  }

  /// Retrieves list of past disease scan records
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_storageKey) ?? [];

    return rawList
        .map((str) => jsonDecode(str) as Map<String, dynamic>)
        .toList();
  }

  /// Returns disease frequency counts map
  static Future<Map<String, int>> getDiseaseFrequencies() async {
    final history = await getScanHistory();
    final Map<String, int> freq = {};

    for (final item in history) {
      final name = (item["disease_name"] ?? "Unknown").toString();
      freq[name] = (freq[name] ?? 0) + 1;
    }

    return freq;
  }

  /// Returns the most common disease name and its count
  static Future<Map<String, dynamic>> getMostCommonDisease() async {
    final freq = await getDiseaseFrequencies();
    if (freq.isEmpty) {
      return {"name": "None Detected", "count": 0};
    }

    String topName = "None Detected";
    int maxCount = 0;

    freq.forEach((name, count) {
      if (count > maxCount) {
        maxCount = count;
        topName = name;
      }
    });

    return {"name": topName, "count": maxCount};
  }

  /// Computes monthly crop health report
  static Future<Map<String, dynamic>> getMonthlyReport() async {
    final history = await getScanHistory();
    final now = DateTime.now();
    final currentMonthStr = "${_getMonthName(now.month)} ${now.year}";

    int total = 0;
    int healthy = 0;
    int diseased = 0;

    for (final item in history) {
      final month = item["month"] ?? currentMonthStr;
      if (month == currentMonthStr || history.length < 5) {
        total++;
        if (item["is_healthy"] == true || (item["disease_name"] ?? "").toString().toLowerCase().contains("healthy")) {
          healthy++;
        } else {
          diseased++;
        }
      }
    }

    final double healthScore = total > 0 ? (healthy / total * 100) : 100.0;

    return {
      "month": currentMonthStr,
      "total_scans": total,
      "healthy_scans": healthy,
      "diseased_scans": diseased,
      "health_index": roundDouble(healthScore, 1),
    };
  }

  /// Clears scan history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  static double roundDouble(double val, int places) {
    return double.parse(val.toStringAsFixed(places));
  }
}
