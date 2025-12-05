import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'chat_storage.dart';

class ChatPage extends StatefulWidget {
  final String userId; // NHẬN userId từ login

  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController inputCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  late GenerativeModel model;

  @override
  void initState() {
    super.initState();

    model = GenerativeModel(
      model: "gemini-2.5-flash",
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );

    loadHistory();
  }

  // ===== Load từ Supabase =====
  Future<void> loadHistory() async {
    final data = await ChatStorage.loadMessages(widget.userId);

    setState(() => messages = data);

    // Nếu không có tin nhắn thì thêm câu chào
    if (messages.isEmpty) {
      messages.add({
        "role": "ai",
        "text": "Chào bạn! Tôi có thể giúp gì cho bạn hôm nay?",
      });

      ChatStorage.saveMessage(
        widget.userId,
        "ai",
        "Chào bạn! Tôi có thể giúp gì cho bạn hôm nay?",
      );
    }

    scrollDown();
  }

  // ===== Format Text AI =====
  String formatText(String text) {
    return text.replaceAll("**", "").replaceAll("* ", "• ").trim();
  }

  // ===== Scroll xuống =====
  void scrollDown() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===========================================================
  //                        SEND TEXT
  // ===========================================================
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    ChatStorage.saveMessage(widget.userId, "user", text);

    inputCtrl.clear();
    scrollDown();

    try {
      final r = await model.generateContent([
        Content.text(
          "Bạn là AgriVision – trợ lý AI chuyên về nông nghiệp, cây trồng, đặc biệt là cây mít. "
          "Hãy trả lời một cách rõ ràng, đúng chuyên môn, tránh lan man. "
          "Nếu câu hỏi không thuộc lĩnh vực nông nghiệp thì hãy nhẹ nhàng hướng người dùng quay lại chủ đề.",
        ),
        Content.text(text),
      ]);

      final answer = formatText(r.text ?? "AI không phản hồi.");

      setState(() {
        messages.add({"role": "ai", "text": answer});
      });

      ChatStorage.saveMessage(widget.userId, "ai", answer);
    } catch (e) {
      final err = "Lỗi AI: $e";
      messages.add({"role": "ai", "text": err});
      ChatStorage.saveMessage(widget.userId, "ai", err);
    }

    setState(() => isLoading = false);
    scrollDown();
  }

  // ===========================================================
  //                     SEND FILE (ẢNH)
  // ===========================================================
  Future<void> sendFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null) return;

    final p = picked.files.first;
    Uint8List? bytes = p.bytes;

    if (bytes == null) return;

    setState(() {
      messages.add({"role": "user", "file": bytes, "filename": p.name});
      isLoading = true;
    });

    ChatStorage.saveMessage(
      widget.userId,
      "user",
      "",
      fileBytes: bytes,
      filename: p.name,
    );

    scrollDown();

    final content = [
      Content.multi([
        TextPart(
          "Bạn là AgriVision – AI chuyên phân tích hình ảnh nông nghiệp. "
          "Hãy phân tích trái mít trong ảnh: giống, độ chín, sâu bệnh, kích thước, khuyến nghị chăm sóc. "
          "Chỉ trả lời đúng chuyên môn.",
        ),
        DataPart("image/jpeg", bytes),
      ]),
    ];

    try {
      final r = await model.generateContent(content);
      final answer = formatText(r.text ?? "Không phân tích được ảnh.");

      setState(() {
        messages.add({"role": "ai", "text": answer});
      });

      ChatStorage.saveMessage(widget.userId, "ai", answer);
    } catch (e) {
      final err = "Lỗi khi phân tích ảnh: $e";
      messages.add({"role": "ai", "text": err});
      ChatStorage.saveMessage(widget.userId, "ai", err);
    }

    setState(() => isLoading = false);
    scrollDown();
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6DBE45),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "AgriVision Chat AI",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => buildBubble(messages[i]),
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _Typing(),
            ),

          _inputBar(),
        ],
      ),
    );
  }

  Widget buildBubble(Map<String, dynamic> msg) {
    final isUser = msg["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6DBE45) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
          ],
        ),
        child: msg["file"] != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg["filename"] ?? "",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      msg["file"],
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              )
            : Text(
                msg["text"],
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: sendFile,
            icon: const Icon(Icons.image, color: Color(0xFF6DBE45)),
          ),
          Expanded(
            child: TextField(
              controller: inputCtrl,
              decoration: const InputDecoration(
                hintText: "Nhắn tin với AgriVision…",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => sendText(inputCtrl.text),
            icon: const Icon(Icons.send, color: Color(0xFF6DBE45)),
          ),
        ],
      ),
    );
  }
}

// Hiệu ứng chạy 3 chấm
class _Typing extends StatefulWidget {
  const _Typing();

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final dots = (ctrl.value * 3).floor() + 1;
        return Text(
          "AgriVision AI đang phân tích${"." * dots}",
          style: const TextStyle(color: Colors.grey),
        );
      },
    );
  }
}
