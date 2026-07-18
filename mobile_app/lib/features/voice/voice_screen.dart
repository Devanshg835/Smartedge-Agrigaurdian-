import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/api_service.dart';
import '../../services/tts_service.dart';

const Color kEmerald = Color(0xFF10B981);

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class VoiceScreen extends StatefulWidget {
  final String? initialDisease;

  const VoiceScreen({super.key, this.initialDisease});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;

  final List<String> _quickQuestions = [
    "Kya spray karna chahiye?",
    "Neem oil use kar sakta hu?",
    "Kya fertilizer use karu?",
    "Kal baarish hogi to spray karu?",
    "Kya ye disease dusre paudhon me fail sakti hai?",
  ];

  @override
  void initState() {
    super.initState();
    final diseaseContextStr = widget.initialDisease != null && widget.initialDisease!.isNotEmpty
        ? " (वर्तमान फसल बीमारी: ${widget.initialDisease})"
        : "";

    // Initial greeting message
    _messages.add(
      ChatMessage(
        text: "नमस्ते किसान भाई! मैं आपका SmartEdge AI Crop Doctor हूँ$diseaseContextStr। आप मुझसे अपनी फसल, बीमारी, खाद या छिड़काव से जुड़ा कोई भी सवाल पूछ सकते हैं।",
        isUser: false,
      ),
    );
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
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });

          if (result.finalResult && _textController.text.trim().isNotEmpty) {
            _sendMessage(_textController.text.trim());
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    final userQuery = query.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userQuery, isUser: true));
      _isThinking = true;
    });

    _scrollToBottom();

    final res = await ApiService.sendChatMessage(
      question: userQuery,
      disease: widget.initialDisease,
    );
    final reply = res["reply_hindi"] as String? ?? "क्षमा करें, उत्तर प्राप्त करने में समस्या आई।";

    setState(() {
      _isThinking = false;
      _messages.add(ChatMessage(text: reply, isUser: false));
    });

    _scrollToBottom();
    _speak(reply);
  }

  void _speak(String text) async {
    setState(() => _isSpeaking = true);
    await TTSService.speak(text);
    setState(() => _isSpeaking = false);
  }

  void _stopSpeech() async {
    await TTSService.stop();
    setState(() => _isSpeaking = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    TTSService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("AI Crop Doctor Chatbot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded, color: kEmerald),
            onPressed: _isSpeaking ? _stopSpeech : null,
            tooltip: "TTS Controls",
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Active Disease Context Header (if available)
          if (widget.initialDisease != null && widget.initialDisease!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kEmerald.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.coronavirus_outlined, color: kEmerald, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Context: ${widget.initialDisease}",
                    style: const TextStyle(color: kEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Quick Suggestion Chips Horizontal Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            color: const Color(0xFF1E293B),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickQuestions.length,
              itemBuilder: (context, idx) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF0F172A),
                    side: BorderSide(color: kEmerald.withValues(alpha: 0.4)),
                    label: Text(
                      _quickQuestions[idx],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    onPressed: () => _sendMessage(_quickQuestions[idx]),
                  ),
                );
              },
            ),
          ),

          // Messages List View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, idx) {
                if (idx == _messages.length && _isThinking) {
                  return _buildThinkingIndicator();
                }

                final msg = _messages[idx];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Speech & Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                // Mic Button
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.redAccent : kEmerald.withValues(alpha: 0.2),
                      border: Border.all(color: _isListening ? Colors.redAccent : kEmerald),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.white : kEmerald,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "सवाल लिखें या माइक दबाएं...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),

                // Send Button
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: kEmerald),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser ? kEmerald.withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? kEmerald.withValues(alpha: 0.5) : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      msg.isUser ? Icons.person : Icons.health_and_safety_rounded,
                      color: msg.isUser ? Colors.white70 : kEmerald,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      msg.isUser ? "You" : "AI Crop Doctor",
                      style: TextStyle(
                        color: msg.isUser ? Colors.white70 : kEmerald,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (!msg.isUser)
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: kEmerald, size: 18),
                    onPressed: () => _speak(msg.text),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: kEmerald, strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text("AI Crop Doctor सोच रहा है...", style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}