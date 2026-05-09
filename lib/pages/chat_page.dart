import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  final AudioRecorder recorder = AudioRecorder();
  bool isRecording = false;
  String? recordedVoicePath;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final String baseUrl = "https://safespace-jauf.onrender.com";

  List<CaseMessage> _messages = [];
  bool isLoading = true;
  bool _isAtBottom = true;
  bool _isSending = false;
  final Set<String> _failedMessageIds = {}; // Track failed messages

  late Timer _pollingTimer;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOnline = true;
  bool _isTyping= false;
  Future<void> startRecording() async {

    if (await recorder.hasPermission()) {

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(
        const RecordConfig(),
        path: path,
      );

      setState(() {
        isRecording = true;
      });
    }
  }
  Future<void> stopRecording() async {

    final path = await recorder.stop();

    print("VOICE PATH: $path");

    setState(() {
      isRecording = false;
    });

    if (path != null) {

      // store the voice file for preview
      setState(() {
        recordedVoicePath = path;
      });

    }

  }
  Future<void> sendVoiceMessage(String filePath) async {

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/chat/${widget.caseId}/voice"),
    );

    request.fields['sender'] =
    widget.isAdmin
        ? "admin"
        : widget.isCounsellor
        ? "counsellor"
        : "user";

    request.fields['chat_type'] =
    widget.isAdminChat ? "ADMIN" : "COUNSELLOR";

    request.files.add(
      await http.MultipartFile.fromPath(
        'voice',
        filePath,
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      pollMessages(); // refresh chat
    } else {
      print("Voice upload failed: ${response.statusCode}");
    }
  }
  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();
    loadMessages();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => pollMessages(),
    );

    _scrollController.addListener(_scrollListener);

    // Monitor connectivity
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline && _failedMessageIds.isNotEmpty) {
        _retryFailedMessages();
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50;
      if (isAtBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = isAtBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer.cancel();
    _connectivitySubscription.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- FETCH ----------------

  Future<List<CaseMessage>> fetchMessages() async {
    late String url;

    if (widget.isAdmin) {
      url = "$baseUrl/admin/messages/${widget.caseId}";
    } else if (widget.isCounsellor) {
      url = "$baseUrl/counsellor/messages/${widget.caseId}";
    } else {
      if (widget.isAdminChat) {
        url = "$baseUrl/admin/messages/${widget.caseId}?anon_id=${widget.anonId}";
      } else {
        url = "$baseUrl/counsellor/messages/${widget.caseId}";
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

      if (msgs.length != _messages.length) {
        setState(() {
          _messages = msgs;
        });
        if (_isAtBottom) {
          scrollToBottom();
        }
      }
    } catch (_) {}
  }

  void scrollToBottom() {
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

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    if (!_isOnline) {
      _showOfflineMessage();
      return;
    }

    setState(() {
      _isSending = true;
    });

    // Create temporary message
    final tempMessage = CaseMessage(
      sender: widget.isAdmin
          ? "admin"
          : widget.isCounsellor
          ? "counsellor"
          : "user",
      text: text,
      time: DateTime.now(),
      isSending: true,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    setState(() {
      _messages.add(tempMessage);
      _controller.clear();
    });

    scrollToBottom();

    Uri url;
    Map<String, dynamic> body;

    if (widget.isAdmin) {
      url = Uri.parse("$baseUrl/admin/report/${widget.caseId}/message");
      body = {"message_text": text};
    } else if (widget.isCounsellor) {
      url = Uri.parse("$baseUrl/counsellor/report/${widget.caseId}/message");
      body = {"message_text": text};
    } else {
      if (widget.isAdminChat) {
        url = Uri.parse("$baseUrl/report/${widget.caseId}/message");
        body = {"anon_id": widget.anonId, "message_text": text};
      } else {
        url = Uri.parse("$baseUrl/report/${widget.caseId}/counsellor-message");
        body = {"anon_id": widget.anonId, "message_text": text};
      }
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Remove temp message and fetch real ones
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
          _isSending = false;
        });
        await pollMessages();
      } else {
        _handleMessageFailure(tempMessage);
      }
    } catch (e) {
      _handleMessageFailure(tempMessage);
    }
  }

  void _handleMessageFailure(CaseMessage tempMessage) {
    setState(() {
      _isSending = false;
      final index = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        _messages[index] = tempMessage.copyWith(
          hasError: true,
          isSending: false,
        );
        _failedMessageIds.add(tempMessage.id!);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Failed to send message"),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _retryMessage(tempMessage),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _retryMessage(CaseMessage failedMessage) {
    _controller.text = failedMessage.text;
    setState(() {
      _messages.removeWhere((m) => m.id == failedMessage.id);
      _failedMessageIds.remove(failedMessage.id);
    });
    sendMessage();
  }

  void _retryFailedMessages() {
    final failedMessages = _messages.where((m) => m.hasError).toList();
    for (var msg in failedMessages) {
      _retryMessage(msg);
    }
  }

  void _showOfflineMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You're offline. Please check your connection."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ---------------- MESSAGE BUBBLE ----------------

  bool isMine(CaseMessage msg) {
    if (widget.isAdmin) return msg.sender == "admin";
    if (widget.isCounsellor) return msg.sender == "counsellor";
    return msg.sender == "user";
  }

  Widget messageBubble(CaseMessage msg, {bool isFirstInGroup = true, bool isLastInGroup = true}) {
    final mine = isMine(msg);

    return Container(
      margin: EdgeInsets.only(
        top: isFirstInGroup ? 8 : 2,
        bottom: isLastInGroup ? 8 : 2,
        left: mine ? 60 : 8,
        right: mine ? 8 : 60,
      ),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isFirstInGroup && !mine)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                msg.sender == "admin" ? "Admin" :
                msg.sender == "counsellor" ? "Counsellor" : "You",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Row(

            mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (mine && msg.hasError)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _retryMessage(msg),
                    child: const Icon(Icons.refresh, color: Colors.red, size: 18),
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                    MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: mine
                        ? (msg.hasError ? Colors.red[50] : Colors.blue[600])
                        : Colors.grey[200],

                    borderRadius: mine
                        ? const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    )
                        : const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: mine ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            Text(
                              _formatTime(msg.time),
                              style: TextStyle(
                                fontSize: 11,
                                color: mine
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[600],
                              ),
                            ),

                            if (mine) ...[
                              const SizedBox(width: 4),

                              Icon(
                                msg.status == "seen"
                                    ? Icons.done_all
                                    : msg.status == "delivered"
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 14,
                                color: msg.status == "seen"
                                    ? Colors.red
                                    : Colors.white70,
                              ),
                            ],

                            if (msg.isSending)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      mine ? Colors.white70 : Colors.grey[600]!,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Case ${widget.caseId}"),
        actions: [
          if (!_isOnline)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Offline",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ---------------- MESSAGE LIST ----------------
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isClosed
                        ? "This conversation is closed"
                        : "No messages yet",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (!widget.isClosed)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Send a message to start the conversation",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
                : Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg.type == "voice") {
                      return VoiceBubble(
                        url: msg.audioUrl!,
                        mine: isMine(msg),
                      );
                    }

                    final showDateHeader = index == 0 ||
                        !isSameDay(_messages[index-1].time, msg.time);
                    final isFirstInGroup = index == 0 ||
                        _messages[index-1].sender != msg.sender;
                    final isLastInGroup = index == _messages.length-1 ||
                        _messages[index+1].sender != msg.sender;

                    return Column(
                      children: [
                        if (showDateHeader)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDate(msg.time),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        messageBubble(
                          msg,
                          isFirstInGroup: isFirstInGroup,
                          isLastInGroup: isLastInGroup,
                        ),
                      ],
                    );
                  },
                ),
                if (!_isAtBottom && _messages.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 46,
                    child: FloatingActionButton.small(
                      onPressed: scrollToBottom,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text("..."),
                ),
              ),
            ),
          // voice preview
          if (recordedVoicePath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey[100],
              child: Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () async {
                      final player = AudioPlayer();
                      await player.setFilePath(recordedVoicePath!);
                      player.play();
                    },
                  ),

                  const Text("Voice message ready"),

                  const Spacer(),

                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        recordedVoicePath = null;
                      });
                    },
                  )

                ],
              ),
            ),


          // ---------------- INPUT ----------------
          if (widget.isClosed)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This case is closed. Messaging is disabled.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: !_isOnline ? _showOfflineMessage : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Attachment feature coming soon")),
                      );
                    },
                    color: Colors.grey[600],
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isOnline ? "Type a message..." : "You're offline",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _isOnline ? Colors.grey[100] : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      enabled: _isOnline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 🎤 MIC BUTTON (STEP 7)
                  IconButton(
                    icon: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: Colors.red,
                    ),
                    onPressed: () {

                      if (isRecording) {
                        stopRecording();
                      } else {
                        startRecording();
                      }

                    },
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),

                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () async {

                        if (recordedVoicePath != null) {

                          await sendVoiceMessage(recordedVoicePath!);

                          setState(() {
                            recordedVoicePath = null;
                          });

                        } else {
                          sendMessage();
                        }

                      },
                    ),
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
  final bool isSending;
  final bool hasError;
  final String? id;
  final String? status;
  final String type;
  final String? audioUrl;


  CaseMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.isSending = false,
    this.hasError = false,
    this.id,
    this.status = "sent",
    this.type = "text",
    this.audioUrl,
  });

  factory CaseMessage.fromJson(Map<String, dynamic> json) {
    String type = "text";
    String? audioUrl;

    if (json["audio_data"] != null) {
      type = "voice";
      audioUrl =
      "https://safespace-jauf.onrender.com/voice/${json["id"]}";
    }

    return CaseMessage(
      sender: json['sender'],
      text: json['message_text'] ?? "",
      time: DateTime.parse(json['created_at']),
      id: json['id']?.toString(),
      status: json['status'] ?? "sent",
      type: type,
      audioUrl: audioUrl,
    );
  }
  CaseMessage copyWith({
    String? sender,
    String? text,
    DateTime? time,
    bool? isSending,
    bool? hasError,
    String? id,
    String? status,
    String? type,
    String? audioUrl,
  }) {
    return CaseMessage(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      time: time ?? this.time,
      isSending: isSending ?? this.isSending,
      hasError: hasError ?? this.hasError,
      id: id ?? this.id,
      status: status ?? this.status,
      type: type ?? this.type,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

class VoiceBubble extends StatefulWidget {
  final String url;
  final bool mine;

  const VoiceBubble({
    super.key,
    required this.url,
    required this.mine,
  });

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final AudioPlayer player = AudioPlayer();
  bool playing = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      widget.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.mine ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: widget.mine ? Colors.white : Colors.black,
                ),
                onPressed: () async {
                  if (playing) {
                    player.pause();
                  } else {
                    await player.setUrl(widget.url);
                    player.play();
                  }

                  setState(() {
                    playing = !playing;
                  });
                },
              ),
              Text(
                "Voice",
                style: TextStyle(
                  color: widget.mine ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}