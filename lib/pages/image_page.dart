import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/jackfruit_classifier.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF6DBE45);
  final supabase = Supabase.instance.client;

  File? _imageFile;

  String detected = "—";
  String status = "—";
  String confidence = "—";
  String rawLabel = "";

  bool analyzing = false;
  Rect? boxRect;

  final ImagePicker _picker = ImagePicker();
  final JackfruitClassifier _classifier = JackfruitClassifier();
  bool _modelLoaded = false;

  late AnimationController fadeCtrl;
  late FToast fToast;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    fToast = FToast();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fToast.init(context);
    });

    _initModel();
  }

  Future<void> _initModel() async {
    await _classifier.loadModel();
    setState(() => _modelLoaded = _classifier.isLoaded);
  }

  @override
  void dispose() {
    fadeCtrl.dispose();
    super.dispose();
  }

  // ================= TOAST =================
  void showToast(String message, {bool success = true}) {
    fToast.removeQueuedCustomToasts();

    final toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 26,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }

  // ================ RANDOM BOX ================
  Rect randomBox() {
    final r = Random();
    return Rect.fromLTWH(
      40 + r.nextInt(80).toDouble(),
      40 + r.nextInt(80).toDouble(),
      120 + r.nextInt(60).toDouble(),
      120 + r.nextInt(40).toDouble(),
    );
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage(ImageSource source) async {
    if (!_modelLoaded) {
      showToast("Model đang tải, vui lòng đợi...", success: false);
      return;
    }

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      analyzing = true;
      _imageFile = file;
      detected = "—";
      status = "—";
      confidence = "—";
      rawLabel = "";
      boxRect = null;
    });

    await _analyzeImage(file);
  }

  // ================= ANALYZE =================
  Future<void> _analyzeImage(File file) async {
    try {
      final result = await _classifier.classify(file);

      final rLabel = (result['label'] ?? '').toString();
      final conf = (result['confidence'] ?? 0.0) as double;

      setState(() {
        rawLabel = rLabel;
        analyzing = false;
        detected = _mapLabelToText(rLabel);
        status = _mapLabelToStatus(rLabel);
        confidence = "${(conf * 100).toStringAsFixed(1)}%";
        boxRect = randomBox();
      });

      fadeCtrl.forward(from: 0);

      await _saveHistory(file, rLabel, conf);
    } catch (e) {
      analyzing = false;
      showToast("Lỗi phân tích ảnh!", success: false);
    }
  }

  // ================= SAVE HISTORY =================
  Future<void> _saveHistory(File file, String label, double conf) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        showToast("Bạn chưa đăng nhập!", success: false);
        return;
      }

      final bytes = await file.readAsBytes();
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

      // Upload file
      await supabase.storage.from("history").uploadBinary(fileName, bytes);

      final imageUrl = supabase.storage.from("history").getPublicUrl(fileName);

      // Insert record
      await supabase.from("jackfruit_history").insert({
        "user_id": user.id,
        "image_url": imageUrl,
        "label": label,
        "confidence": conf,
      });

      showToast("Đã lưu lịch sử phân tích!");
    } catch (e) {
      print("🔥 Lỗi lưu lịch sử: $e");
      showToast("Không thể lưu lịch sử!", success: false);
    }
  }

  // ================ LABEL MAP =================
  String _mapLabelToText(String label) {
    switch (label) {
      case 'mit_chin':
        return 'Mít chín';
      case 'mit_non':
        return 'Mít non';
      case 'mit_saubenh':
        return 'Mít sâu bệnh';
      default:
        return 'Không xác định';
    }
  }

  String _mapLabelToStatus(String label) {
    switch (label) {
      case 'mit_chin':
        return 'Tốt – có thể thu hoạch';
      case 'mit_non':
        return 'Cần thời gian chín thêm';
      case 'mit_saubenh':
        return 'Có dấu hiệu sâu bệnh – cần xử lý';
      default:
        return 'Không rõ tình trạng';
    }
  }

  Color _getColor(String label) {
    switch (label) {
      case "mit_chin":
        return Colors.amber;
      case "mit_non":
        return Colors.green;
      case "mit_saubenh":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FFEA),
      appBar: AppBar(
        title: const Text(
          "Phân tích hình ảnh",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6DBE45),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _previewBox(),
            const SizedBox(height: 20),
            _buttons(),
            const SizedBox(height: 30),
            _resultBox(),
          ],
        ),
      ),
    );
  }

  // ================= PREVIEW IMAGE =================
  Widget _previewBox() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          _imageFile != null
              ? FadeTransition(
                  opacity: fadeCtrl,
                  child: Image.file(
                    _imageFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),

          // ================= BOUNDING BOX =================
          if (boxRect != null && rawLabel.isNotEmpty)
            Positioned(
              left: boxRect!.left,
              top: boxRect!.top,
              child: Stack(
                children: [
                  Container(
                    width: boxRect!.width,
                    height: boxRect!.height,
                    decoration: BoxDecoration(
                      border: Border.all(color: _getColor(rawLabel), width: 3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Positioned(
                    top: -28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getColor(rawLabel),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        detected,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (analyzing)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Đang phân tích...",
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= BUTTONS =================
  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text(
            "Tải ảnh lên",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text("Chụp ảnh", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  // ================= RESULT =================
  Widget _resultBox() {
    final hasData = detected != "—";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kết quả phân tích",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _item("Nhận dạng:", detected),
                _item("Tình trạng:", status),
                _item("Độ tin cậy:", confidence),
              ],
            )
          : const Text(
              "Chưa có dữ liệu.\nNhấn tải ảnh lên hoặc chụp ảnh để phân tích.",
              style: TextStyle(fontSize: 15),
            ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
