import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/history_service.dart';

const Color kEmerald = Color(0xFF10B981);

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> _history = [];
  Map<String, int> _diseaseFrequency = {};
  Map<String, dynamic> _mostCommon = {};
  Map<String, dynamic> _monthlyReport = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final history = await HistoryService.getScanHistory();
    final freq = await HistoryService.getDiseaseFrequencies();
    final mostCommon = await HistoryService.getMostCommonDisease();
    final monthly = await HistoryService.getMonthlyReport();

    setState(() {
      _history = history;
      _diseaseFrequency = freq;
      _mostCommon = mostCommon;
      _monthlyReport = monthly;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await HistoryService.clearHistory();
    await _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final totalScans = _monthlyReport["total_scans"] ?? _history.length;
    final healthyScans = _monthlyReport["healthy_scans"] ?? 0;
    final diseasedScans = _monthlyReport["diseased_scans"] ?? 0;
    final healthIndex = (_monthlyReport["health_index"] ?? 100.0).toString();
    final activeMonth = _monthlyReport["month"] ?? "Current Month";

    final topDisease = _mostCommon["name"] ?? "None Detected";
    final topCount = _mostCommon["count"] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Crop Analytics & Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _clearHistory,
              tooltip: "Clear History",
            ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kEmerald))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Overview Stat Cards
                  Row(
                    children: [
                      _buildStatCard("Total Scans", "$totalScans", Icons.center_focus_strong, Colors.blueAccent),
                      const SizedBox(width: 10),
                      _buildStatCard("Diseased", "$diseasedScans", Icons.warning_amber_rounded, Colors.orangeAccent),
                      const SizedBox(width: 10),
                      _buildStatCard("Healthy", "$healthyScans", Icons.check_circle_outline, kEmerald),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Most Common Disease & Monthly Report Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: Colors.orangeAccent, size: 18),
                                  SizedBox(width: 6),
                                  Text("Most Common", style: TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                topDisease,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text("$topCount scan occurrences", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kEmerald.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.date_range_rounded, color: kEmerald, size: 18),
                                  const SizedBox(width: 6),
                                  Text(activeMonth, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$healthIndex% Healthy",
                                style: const TextStyle(color: kEmerald, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text("Monthly Health Index", style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Interactive fl_chart Bar Chart (Disease Frequency)
                  if (_diseaseFrequency.isNotEmpty) ...[
                    const Text("Disease Frequency Chart", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_diseaseFrequency.values.isEmpty ? 5 : (_diseaseFrequency.values.reduce((a, b) => a > b ? a : b) + 1)).toDouble(),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final keys = _diseaseFrequency.keys.toList();
                                  if (val.toInt() >= 0 && val.toInt() < keys.length) {
                                    final shortName = keys[val.toInt()].split("_").first;
                                    return Text(shortName, style: const TextStyle(color: Colors.white54, fontSize: 10));
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _diseaseFrequency.entries.toList().asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value.toDouble(),
                                  color: e.value.key.toLowerCase().contains("healthy") ? kEmerald : Colors.orangeAccent,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. Interactive fl_chart Pie Chart (Health Distribution Ratio)
                  if (_history.isNotEmpty) ...[
                    const Text("Crop Health Distribution", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 35,
                                sections: [
                                  PieChartSectionData(
                                    color: kEmerald,
                                    value: healthyScans.toDouble() > 0 ? healthyScans.toDouble() : 1,
                                    title: healthyScans > 0 ? "$healthyScans" : "0",
                                    radius: 35,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.orangeAccent,
                                    value: diseasedScans.toDouble() > 0 ? diseasedScans.toDouble() : 0.01,
                                    title: diseasedScans > 0 ? "$diseasedScans" : "",
                                    radius: 35,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 12, height: 12, color: kEmerald),
                                  const SizedBox(width: 8),
                                  Text("Healthy ($healthyScans)", style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(width: 12, height: 12, color: Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Text("Diseased ($diseasedScans)", style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 5. Recent Scan Timeline Feed
                  const Text("Recent Scan Timeline", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          "No scan history recorded yet.\nScan crop leaves using the Scan tab to build your analytics timeline.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final name = item["disease_name"] ?? "Unknown";
                        final conf = ((item["confidence"] ?? 0.0) * 100).toStringAsFixed(1);
                        final dateStr = item["timestamp"] ?? "";
                        final isHealthy = item["is_healthy"] == true || name.toString().toLowerCase().contains("healthy");

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isHealthy ? kEmerald.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: (isHealthy ? kEmerald : Colors.orangeAccent).withValues(alpha: 0.2),
                                child: Icon(
                                  isHealthy ? Icons.eco_rounded : Icons.bug_report_rounded,
                                  color: isHealthy ? kEmerald : Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text("Confidence: $conf% • $dateStr", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}