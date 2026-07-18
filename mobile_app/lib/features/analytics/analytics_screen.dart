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
  String _mostCommonDisease = "None";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    final data = await HistoryService.getScanHistory();
    final Map<String, int> freq = {};

    for (final item in data) {
      final String name = (item["disease_name"] ?? "Unknown").toString();
      freq[name] = (freq[name] ?? 0) + 1;
    }

    String topDisease = "None";
    int maxCount = 0;
    freq.forEach((name, count) {
      if (count > maxCount) {
        maxCount = count;
        topDisease = name;
      }
    });

    setState(() {
      _history = data;
      _diseaseFrequency = freq;
      _mostCommonDisease = topDisease;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await HistoryService.clearHistory();
    await _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    final totalScans = _history.length;
    final healthyScans = _history.where((item) => (item["disease_name"] ?? "").toString().toLowerCase().contains("healthy")).length;
    final diseaseScans = totalScans - healthyScans;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Crop Health Analytics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  // Overview Stat Cards
                  Row(
                    children: [
                      _buildStatCard("Total Scans", "$totalScans", Icons.center_focus_strong, Colors.blueAccent),
                      const SizedBox(width: 10),
                      _buildStatCard("Diseased", "$diseaseScans", Icons.warning_amber_rounded, Colors.orangeAccent),
                      const SizedBox(width: 10),
                      _buildStatCard("Healthy", "$healthyScans", Icons.check_circle_outline, kEmerald),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Most Common Disease Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insights_rounded, color: Colors.orangeAccent, size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Most Common Disease", style: TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                _mostCommonDisease,
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chart Section (fl_chart Bar Chart)
                  if (_diseaseFrequency.isNotEmpty) ...[
                    const Text("Disease Occurrence Chart", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
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
                          barTouchData: BarTouchDataEnabled(enabled: true),
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
                                  color: kEmerald,
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

                  // Scan History & Timeline List
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
                          "No scan history available.\nScan crop leaves using the Scan tab to populate analytics.",
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
                        final isHealthy = name.toString().toLowerCase().contains("healthy");

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