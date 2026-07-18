import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Service - handles all communication with the Python backend
/// (kb_matcher.py + weather_advisor.py wrapped in app.py / Flask)
///
/// IMPORTANT: Update [baseUrl] below with your PC's local IP address.
/// Find it by running `ipconfig` (Windows) on the PC running the backend,
/// and look for "IPv4 Address" under your active WiFi adapter.
/// The phone and PC must be on the same WiFi network / hotspot.
class ApiService {
  // TODO: Replace with your PC's actual local IP address
  static const String baseUrl = "http://10.92.212.144:5000";

  static const Duration _timeout = Duration(seconds: 20);

  /// Sends a farmer's query to the AI Crop Doctor / Voice Assistant backend.
  /// Returns a map with keys: source, response, matched_id
  static Future<Map<String, dynamic>> getAdvisory({
    required String query,
    String? cropHint,
    Map<String, dynamic>? sensorContext,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/advisory"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "query": query,
              if (cropHint != null) "crop_hint": cropHint,
              if (sensorContext != null) "sensor_context": sensorContext,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          "source": "error",
          "response": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "source": "error",
        "response":
            "Could not reach the server. Make sure your phone and PC are "
            "on the same WiFi network and the backend server is running.\n\nDetails: $e",
      };
    }
  }

  /// Fetches the combined dashboard summary: weather + irrigation advice +
  /// crop recommendation, based on current soil moisture reading.
  static Future<Map<String, dynamic>?> getDashboardSummary({
    required double moisture,
    String city = "Ghaziabad",
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/dashboard?moisture=$moisture&city=$city",
      );
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Simple check to confirm the backend server is reachable.
  static Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}