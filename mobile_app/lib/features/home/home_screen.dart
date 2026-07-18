import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/history_service.dart';
import '../scan/scan_screen.dart';
import '../voice/voice_screen.dart';

const Color kEmerald = Color(0xFF10B981);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _sensorData;
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _lastScanRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final sensors = await ApiService.getSensorData();
    final weather = await ApiService.getWeather();
    final history = await HistoryService.getScanHistory();

    setState(() {
      _sensorData = sensors ?? {
        "soil_moisture": 45.0,
        "temperature": 28.5,
        "humidity": 62.0,
      };
      _weatherData = weather;
      _lastScanRecord = history.isNotEmpty ? history.first : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double moisture = ((_sensorData?["soil_moisture"] as num?) ?? 45.0).toDouble();
    final double temp = ((_sensorData?["temperature"] as num?) ?? 28.5).toDouble();
    final double humidity = ((_sensorData?["humidity"] as num?) ?? 62.0).toDouble();

    final lastDisease = _lastScanRecord?["disease_name"] ?? "No Recent Scans";
    final lastConf = _lastScanRecord != null
        ? (((_lastScanRecord!["confidence"] as num?) ?? 0.95) * 100).toStringAsFixed(1)
        : "N/A";
    final lastActionPlan = _lastScanRecord?["action_plan"] as Map<String, dynamic>?;
    final todayTasks = List<String>.from(lastActionPlan?["today"] ?? ["Perform regular leaf scan"]);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          color: kEmerald,
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Namaste, Kisan 🌾",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "SmartEdge AI Crop Health Dashboard",
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: kEmerald),
                      onPressed: _loadDashboardData,
                      tooltip: "Refresh Data",
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: kEmerald),
                    ),
                  )
                else ...[
                  // 1. Disease Card & 2. Confidence Card Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          title: "Recent Disease",
                          value: lastDisease,
                          icon: Icons.bug_report_rounded,
                          color: lastDisease.contains("Healthy") ? kEmerald : Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCard(
                          title: "Match Confidence",
                          value: lastConf == "N/A" ? "N/A" : "$lastConf%",
                          icon: Icons.verified_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Treatment Card & 4. Action Plan Card
                  _buildActionPlanCard(todayTasks),
                  const SizedBox(height: 14),

                  // 5. Weather Card
                  _buildWeatherCard(),
                  const SizedBox(height: 14),

                  // 6. Sensor Card Row
                  const Text("Arduino UNO Q Live Sensors", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorMetric("Moisture", "$moisture%", Icons.water_drop_rounded, kEmerald),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSensorMetric("Temperature", "$temp°C", Icons.thermostat_rounded, Colors.amber),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSensorMetric("Humidity", "$humidity%", Icons.air_rounded, Colors.cyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 7. History Card & 8. AI Crop Doctor Quick Card
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kEmerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ScanScreen()),
                            );
                          },
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                          label: const Text("Scan Leaf", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kEmerald),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const VoiceScreen()),
                            );
                          },
                          icon: const Icon(Icons.health_and_safety_rounded, color: kEmerald),
                          label: const Text("AI Doctor", style: TextStyle(color: kEmerald, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanCard(List<String> tasks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kEmerald.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: kEmerald, size: 20),
              SizedBox(width: 8),
              Text("Today's Treatment & Action Plan", style: TextStyle(color: kEmerald, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: kEmerald, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final cond = _weatherData?["condition"] ?? "Clear / Fair Weather";
    final temp = _weatherData?["temperature"] ?? 28.0;
    final rainProb = _weatherData?["rain_probability"] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, color: Colors.blueAccent, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Weather: $cond", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Temp: $temp°C • Rain Probability: $rainProb%", style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}