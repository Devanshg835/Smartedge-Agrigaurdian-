import 'dart:io';
import 'package:flutter/material.dart';

const Color kEmerald = Color(0xFF10B981);

class ScanResultScreen extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> scanResult;
  final Map<String, dynamic> diseaseInfo;
  final Map<String, dynamic> actionPlan;
  final String? advisoryHindi;

  const ScanResultScreen({
    super.key,
    required this.imageFile,
    required this.scanResult,
    required this.diseaseInfo,
    required this.actionPlan,
    this.advisoryHindi,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  @override
  Widget build(BuildContext context) {
    final diseaseName = widget.diseaseInfo["name"] ?? widget.scanResult["disease_name"] ?? "Crop Disease";
    final scientificName = widget.diseaseInfo["scientific_name"] ?? "";
    final severity = widget.diseaseInfo["severity"] ?? "Medium";
    final yieldLoss = widget.diseaseInfo["yield_loss"] ?? "15-30%";
    final confidence = ((widget.scanResult["confidence"] ?? 0.95) * 100).toStringAsFixed(1);

    final symptoms = List<String>.from(widget.diseaseInfo["symptoms"] ?? []);
    final causes = List<String>.from(widget.diseaseInfo["causes"] ?? []);
    final organic = List<String>.from(widget.diseaseInfo["organic_treatment"] ?? []);
    final chemical = List<String>.from(widget.diseaseInfo["chemical_treatment"] ?? []);
    final recFertilizers = List<String>.from(widget.diseaseInfo["recommended_fertilizers"] ?? []);
    final avoidFertilizers = List<String>.from(widget.diseaseInfo["avoid_fertilizers"] ?? []);
    final wateringAdvice = widget.diseaseInfo["watering_advice"] as String? ?? "Maintain regular drip watering.";

    final todayPlan = List<String>.from(widget.actionPlan["today"] ?? []);
    final next3Plan = List<String>.from(widget.actionPlan["next_3_days"] ?? []);
    final nextWeekPlan = List<String>.from(widget.actionPlan["next_week"] ?? []);
    final recoveryTime = widget.actionPlan["expected_recovery"] as String? ?? "10-14 Days";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Scan Result & Diagnosis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Header
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kEmerald.withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(widget.imageFile, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),

            // Main Disease & Confidence Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kEmerald.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          diseaseName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kEmerald),
                        ),
                        child: Text(
                          "$confidence% Match",
                          style: const TextStyle(color: kEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (scientificName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      scientificName,
                      style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 6),
                      Text("Severity: $severity", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.trending_down_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 6),
                      Text("Yield Loss: $yieldLoss", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 6),
                      Text("Recovery Time: $recoveryTime", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Symptoms & Causes Section
            if (symptoms.isNotEmpty) _buildListCard("Symptoms", symptoms, Icons.coronavirus_outlined, Colors.amber),
            if (symptoms.isNotEmpty) const SizedBox(height: 10),
            if (causes.isNotEmpty) _buildListCard("Causes", causes, Icons.bug_report_outlined, Colors.orangeAccent),
            if (causes.isNotEmpty) const SizedBox(height: 16),

            // Action Plan Section
            const Text("Smart Action Plan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildListCard("Today's Action Plan", todayPlan, Icons.today, kEmerald),
            const SizedBox(height: 10),
            _buildListCard("Next 3 Days", next3Plan, Icons.calendar_view_week, Colors.amber),
            const SizedBox(height: 10),
            _buildListCard("Next Week", nextWeekPlan, Icons.date_range, Colors.cyan),
            const SizedBox(height: 16),

            // Treatments & Fertilizers Section
            const Text("Treatment & Care Recommendations", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (organic.isNotEmpty) _buildListCard("Organic Treatment", organic, Icons.eco, kEmerald),
            if (organic.isNotEmpty) const SizedBox(height: 10),
            if (chemical.isNotEmpty) _buildListCard("Chemical Treatment", chemical, Icons.science, Colors.purpleAccent),
            if (chemical.isNotEmpty) const SizedBox(height: 10),

            _buildInfoCard("Watering Advice", wateringAdvice, Icons.water_drop, Colors.blueAccent),
            const SizedBox(height: 10),
            if (recFertilizers.isNotEmpty) _buildListCard("Recommended Fertilizers", recFertilizers, Icons.grass, kEmerald),
            if (recFertilizers.isNotEmpty) const SizedBox(height: 10),
            if (avoidFertilizers.isNotEmpty) _buildListCard("Avoid Fertilizers", avoidFertilizers, Icons.block, Colors.redAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: color.withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
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

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
