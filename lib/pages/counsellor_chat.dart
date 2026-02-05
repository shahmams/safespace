import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CounsellorChatPage extends StatefulWidget {
  final String caseId;
  final bool isClosed;

  const CounsellorChatPage({
    super.key,
    required this.caseId,
    required this.isClosed,
  });

  @override
  State<CounsellorChatPage> createState() => _CounsellorChatPageState();
}

class _CounsellorChatPageState extends State<CounsellorChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String baseUrl = "https://safespace-backend-z4d6.onrender.com";

  List<CaseMessage> _messages = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // ⏱ Poll every 6 seconds (SAFE – no blinking)
    _timer = Timer.periodic(
      const Duration(seconds: 6),
          (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- FETCH MESSAGES ----------------

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/counsellor/messages/${widget.caseId}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['messages'];

        final newMessages =
        list.map((e) => CaseMessage.fromJson(e)).toList();

        if (!mounted) return;

        setState(() {
          _messages = newMessages;
          _loading = false;
        });

        if (!silent) _scrollToBottom();
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _loading = false);
      }
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

  // ---------------- SEND MESSAGE ----------------

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await http.post(
        Uri.parse(
          "$baseUrl/counsellor/report/${widget.caseId}/message",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message_text": text}),
      );

      _controller.clear();
      await _loadMessages();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message")),
      );
    }
  }

  // ---------------- MESSAGE BUBBLE ----------------

  Widget _bubble(CaseMessage msg) {
    final isMe = msg.sender == "counsellor";

    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 10,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.time),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Counselling – ${widget.caseId}"),
      ),
      body: Column(
        children: [
          // ---------------- MESSAGE LIST ----------------
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text("No messages yet"))
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (_, i) => _bubble(_messages[i]),
            ),
          ),

          // ---------------- INPUT ----------------
          if (widget.isClosed)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Counselling closed. Messaging disabled.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Type your message…",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- MODEL ----------------

class CaseMessage {
  final String sender;
  final String text;
  final DateTime time;

  CaseMessage({
    required this.sender,
    required this.text,
    required this.time,
  });

  factory CaseMessage.fromJson(Map<String, dynamic> json) {
    return CaseMessage(
      sender: json['sender'],
      text: json['message_text'],
      time: DateTime.parse(json['created_at']),
    );
  }
}
