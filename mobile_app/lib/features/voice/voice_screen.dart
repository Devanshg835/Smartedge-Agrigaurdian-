import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

/// Voice Assistant Screen - "AI Crop Doctor"
/// Flow: Tap mic -> Listen -> Send query to backend -> Show + speak the answer
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = "";
  String _responseText = "";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    // Hindi voice output; falls back to default if not available on the device.
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = "";
        _responseText = "";
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult && _recognizedText.isNotEmpty) {
            _sendQueryToBackend(_recognizedText);
          }
        },
        localeId: "hi_IN", // Hindi speech recognition
      );
    } else {
      setState(() {
        _responseText = "Speech recognition is not available on this device.";
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendQueryToBackend(String query) async {
    setState(() => _isProcessing = true);

    final result = await ApiService.getAdvisory(query: query);

    final String answer = result["response"] ?? "No response received.";

    setState(() {
      _responseText = answer;
      _isProcessing = false;
    });

    // Speak the answer out loud
    await _tts.speak(answer);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Crop Doctor")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Mic Button
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppColors.danger
                        : AppColors.primaryGreen,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                                ? AppColors.danger
                                : AppColors.primaryGreen)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                _isListening
                    ? "Listening... speak now"
                    : "Tap the mic and ask your question",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // Recognized text (what the user said)
              if (_recognizedText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You asked:",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recognizedText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Processing indicator
              if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.lightGreen),
                    SizedBox(height: 10),
                    Text(
                      "Thinking...",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),

              // AI response
              if (_responseText.isNotEmpty && !_isProcessing)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                color: AppColors.lightGreen,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "AgriGuardian AI",
                                style: TextStyle(
                                  color: AppColors.lightGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _responseText,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}