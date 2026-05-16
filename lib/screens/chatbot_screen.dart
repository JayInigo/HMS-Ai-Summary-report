import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// ── Message model ─────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _dataLoaded = false;
  String _checkInContext = '';

  // ── Replace with your actual Groq API key ───────────────────────────────
  // Get a FREE key at: https://console.groq.com → API Keys → Create API Key
  static const String _apiKey = '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';
  // ─────────────────────────────────────────────────────────────────────────

  // Keep conversation history for multi-turn chat
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCheckInData();
  }

  // 1. Load all Firestore check-in data once on screen open
  Future<void> _loadCheckInData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hotel_checkins')
          .orderBy('createdAt', descending: true)
          .get();

      final buffer = StringBuffer();
      buffer.writeln('CURRENT HOTEL CHECK-IN RECORDS (${snapshot.docs.length} total guests):');
      buffer.writeln();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        final date = timestamp != null
            ? timestamp.toDate().toString().substring(0, 16)
            : 'Unknown Date';
        buffer.writeln('- Guest: ${data['clientName'] ?? 'N/A'}');
        buffer.writeln('  Room Type: ${data['roomType'] ?? 'N/A'}');
        buffer.writeln('  Guest Status: ${data['guestStatus'] ?? 'N/A'}');
        buffer.writeln('  Check-in Date: $date');
        buffer.writeln();
      }

      setState(() {
        _checkInContext = buffer.toString();
        _dataLoaded = true;
      });

      // Add welcome message after data loads
      _addBotMessage(
        snapshot.docs.isEmpty
            ? 'Hello! I\'m your hotel staff assistant. There are no check-in records yet. Once guests check in, I can answer questions about them.'
            : 'Hello! I\'m your Velour Grand Hotel staff assistant. I have loaded ${snapshot.docs.length} check-in record(s). You can ask me anything about your guests, room occupancy, or check-in data!',
      );
    } catch (e) {
      _addBotMessage(
          'Hello! I\'m your hotel staff assistant. I had trouble loading check-in data: $e');
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || _isTyping) return;

    _inputController.clear();

    setState(() {
      _messages.add(ChatMessage(text: input, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // Add user message to history
    _conversationHistory.add({'role': 'user', 'content': input});

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 512,
          'temperature': 0.6,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful hotel staff assistant for Velour Grand Hotel in the Philippines. '
                  'You help hotel staff by answering questions about guest check-ins, room occupancy, and hotel operations. '
                  'Be concise, professional, and friendly. '
                  'Always base your answers on the provided check-in data when relevant. '
                  'If asked about something not in the data, say so honestly.\n\n'
                  'Here is the current hotel check-in data:\n\n$_checkInContext',
            },
            ..._conversationHistory,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['choices'][0]['message']['content'] as String;

        // Add assistant reply to history
        _conversationHistory.add({'role': 'assistant', 'content': reply});
        _addBotMessage(reply);
      } else {
        final errorData = jsonDecode(response.body);
        _addBotMessage(
            'Sorry, I encountered an error: ${errorData['error']?['message'] ?? response.statusCode}');
      }
    } catch (e) {
      _addBotMessage('Sorry, something went wrong: $e');
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
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

  // Quick suggestion chips
  final List<String> _suggestions = [
    'How many guests checked in?',
    'Which room type is most popular?',
    'List all Deluxe room guests',
    'Any VIP guests?',
    'How many Suite bookings?',
    'Who checked in most recently?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff Assistant',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Velour Grand Hotel',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        backgroundColor: const Color(0xFF8B0000),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Online indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('Online',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Loading banner ──────────────────────────────────────────────
          if (!_dataLoaded)
            Container(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF8B0000)),
                  ),
                  SizedBox(width: 8),
                  Text('Loading check-in data...',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF8B0000))),
                ],
              ),
            ),

          // ── Chat messages ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // ── Typing indicator ────────────────────────────────────────────
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  _botAvatar(),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4)
                      ],
                    ),
                    child: const Row(
                      children: [
                        _TypingDot(delay: 0),
                        SizedBox(width: 4),
                        _TypingDot(delay: 200),
                        SizedBox(width: 4),
                        _TypingDot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Suggestion chips ────────────────────────────────────────────
          if (_messages.length <= 1 && _dataLoaded)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _inputController.text = _suggestions[index];
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF8B0000).withOpacity(0.4)),
                      ),
                      child: Text(
                        _suggestions[index],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8B0000)),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // ── Input bar ───────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Ask about your guests...',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B0000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _botAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF8B0000)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.support_agent, color: Colors.white, size: 18),
    );
  }
}

// ── Animated typing dot ───────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
    _animation = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF8B0000),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}