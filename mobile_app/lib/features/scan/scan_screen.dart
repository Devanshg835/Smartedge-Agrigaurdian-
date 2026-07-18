import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/history_service.dart';
import 'scan_result_screen.dart';

const Color kEmerald = Color(0xFF10B981);

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null) return;

      setState(() {
        _selectedImage = File(file.path);
      });

      await _runDiseaseDetection(_selectedImage!);
    } catch (e) {
      _showSnackBar("Image pick error: $e");
    }
  }

  Future<void> _runDiseaseDetection(File imageFile) async {
    setState(() => _isLoading = true);

    final detectRes = await ApiService.detectLeafDisease(imageFile);

    if (detectRes["status"] == "error") {
      setState(() => _isLoading = false);
      _showSnackBar(detectRes["message"] ?? "Detection failed");
      return;
    }

    final double confidence = (detectRes["confidence"] as num? ?? 0.0).toDouble();
    final String label = detectRes["label"] as String? ?? detectRes["disease"] ?? "Unknown";

    // 70% Gate Filter Check
    if (confidence < 0.70) {
      setState(() => _isLoading = false);
      _showLowConfidenceDialog(confidence);
      return;
    }

    // Fetch AI Crop Doctor Advisory (Hindi + Action Plan)
    final doctorRes = await ApiService.getCropDoctorAdvisory(
      disease: label,
      confidence: confidence,
    );
    setState(() => _isLoading = false);

    final actionPlan = (doctorRes["action_plan"] as Map<String, dynamic>?) ?? {};
    final diseaseInfo = (doctorRes["disease_info"] as Map<String, dynamic>?) ?? {};
    final advisoryHindi = doctorRes["advisory_hindi"] as String?;

    // Save to local history
    await HistoryService.addScanRecord(
      diseaseName: detectRes["disease_name"] ?? diseaseInfo["name"] ?? label,
      confidence: confidence,
      actionPlan: actionPlan,
      sensorData: doctorRes["sensor_data"] as Map<String, dynamic>?,
      imagePath: imageFile.path,
    );

    // Navigate to dedicated ScanResultScreen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          imageFile: imageFile,
          scanResult: detectRes,
          diseaseInfo: diseaseInfo,
          actionPlan: actionPlan,
          advisoryHindi: advisoryHindi,
        ),
      ),
    );
  }

  void _showLowConfidenceDialog(double confidence) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text("Low Confidence", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "Detection confidence was ${(confidence * 100).toStringAsFixed(1)}%.\n\n"
          "Low confidence. Please capture another image in good lighting.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kEmerald,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: const Text("Retake Photo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("YOLO Disease Detection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kEmerald.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.camera_alt_outlined, color: kEmerald, size: 48),
                  SizedBox(height: 12),
                  Text(
                    "AI Crop Doctor Leaf Scanner",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Capture or upload a clear photo of an infected leaf (Tomato, Potato, Pepper) for instant diagnosis.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Image Preview Box
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kEmerald.withValues(alpha: 0.3), width: 1.5),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.center_focus_weak_rounded, size: 64, color: kEmerald),
                          SizedBox(height: 12),
                          Text(
                            "No leaf image selected",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: kEmerald),
                      SizedBox(height: 10),
                      Text("Analyzing leaf image with YOLO11...", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            if (!_isLoading)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text("Take Photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kEmerald),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: kEmerald),
                      label: const Text("Gallery", style: TextStyle(color: kEmerald, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}