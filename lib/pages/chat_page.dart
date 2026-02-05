import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String caseId;
  final String? anonId; // null for admin
  final bool isAdmin;
  final bool isCounsellor;
  final bool isAdminChat;
  final bool isClosed;

  const ChatPage({
    super.key,
    required this.caseId,
    this.anonId,
    required this.isAdmin,
    required this.isCounsellor,
    required this.isAdminChat,
    required this.isClosed,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String baseUrl = "https://safespace-backend-z4d6.onrender.com";

  List<CaseMessage> _messages = [];
  bool isLoading = true;

  late Timer _pollingTimer;

  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();
    loadMessages();

    // Poll every 5 seconds WITHOUT rebuilding whole UI
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => pollMessages(),
    );
  }

  @override
  void dispose() {
    _pollingTimer.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- FETCH ----------------

  Future<List<CaseMessage>> fetchMessages() async {
    late String url;

    if (widget.isAdmin) {
      // Admin ↔ User
      url = "$baseUrl/admin/messages/${widget.caseId}";
    }
    else if (widget.isCounsellor) {
      // Counsellor ↔ User
      url = "$baseUrl/counsellor/messages/${widget.caseId}";
    }
    else {
      // USER
      if (widget.isAdminChat) {
        // User ↔ Admin
        url =
        "$baseUrl/admin/messages/${widget.caseId}?anon_id=${widget.anonId}";
      } else {
        // User ↔ Counsellor
        url =
        "$baseUrl/counsellor/messages/${widget.caseId}";
      }
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("Failed to load messages");
    }

    final data = jsonDecode(response.body);
    final List msgs = data['messages'];

    return msgs.map((m) => CaseMessage.fromJson(m)).toList();
  }


  Future<void> loadMessages() async {
    try {
      final msgs = await fetchMessages();
      if (!mounted) return;

      setState(() {
        _messages = msgs;
        isLoading = false;
      });

      scrollToBottom();
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> pollMessages() async {
    try {
      final msgs = await fetchMessages();
      if (!mounted) return;

      // Update ONLY if new messages exist
      if (msgs.length != _messages.length) {
        setState(() {
          _messages = msgs;
        });
        scrollToBottom();
      }
    } catch (_) {}
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  // ---------------- SEND MESSAGE ----------------

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    Uri url;
    Map<String, dynamic> body;

    if (widget.isAdmin) {
      // Admin → User
      url = Uri.parse(
        "$baseUrl/admin/report/${widget.caseId}/message",
      );
      body = {"message_text": text};

    } else if (widget.isCounsellor) {
      // Counsellor → User
      url = Uri.parse(
        "$baseUrl/counsellor/report/${widget.caseId}/message",
      );
      body = {"message_text": text};

    } else {
      // USER
      if (widget.isAdminChat) {
        // User → Admin
        url = Uri.parse(
          "$baseUrl/report/${widget.caseId}/message",
        );
        body = {
          "anon_id": widget.anonId,
          "message_text": text,
        };
      } else {
        // User → Counsellor
        url = Uri.parse(
          "$baseUrl/report/${widget.caseId}/counsellor-message",
        );
        body = {
          "anon_id": widget.anonId,
          "message_text": text,
        };
      }
    }



    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      _controller.clear();
      await pollMessages();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message")),
      );
    }
  }

  // ---------------- MESSAGE BUBBLE ----------------

  bool isMine(CaseMessage msg) {
    if (widget.isAdmin) return msg.sender == "admin";
    if (widget.isCounsellor) return msg.sender == "counsellor";
    return msg.sender == "user";
  }

  Widget messageBubble(CaseMessage msg) {
    final mine = isMine(msg);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.time),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Case ${widget.caseId}"),
      ),
      body: Column(
        children: [
          // ---------------- MESSAGE LIST ----------------
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text("No messages yet"))
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return messageBubble(_messages[index]);
              },
            ),
          ),

          // ---------------- INPUT ----------------
          if (widget.isClosed)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "This case is closed. Messaging is disabled.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- MESSAGE MODEL ----------------

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
