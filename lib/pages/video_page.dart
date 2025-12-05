import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as VT;

import '../services/video_classifier.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String mode = "video";
  String? videoPath;
  bool webcamActive = false;

  CameraController? _cameraCtrl;
  VideoPlayerController? _videoCtrl;
  Timer? _camTimer;

  final classifier = VideoJackfruitClassifier();
  Map<String, double> resultMap = {};

  bool modelLoaded = false;
  bool analyzingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await classifier.loadModel();
    setState(() => modelLoaded = classifier.isLoaded);
  }

  @override
  void dispose() {
    _camTimer?.cancel();
    _cameraCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  // -------------------------
  // TOAST
  // -------------------------
  void showToast(String msg, {bool success = true}) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: success ? Colors.white : Colors.red.shade300,
      textColor: Colors.black87,
    );
  }

  // -------------------------
  // PERMISSION FOR ANDROID
  // -------------------------
  Future<bool> _requestVideoPermission() async {
    if (!Platform.isAndroid) return true;

    final info = await DeviceInfoPlugin().androidInfo;

    if (info.version.sdkInt >= 33) {
      final videos = await Permission.videos.request();
      return videos.isGranted;
    } else {
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
  }

  // -------------------------
  // UPLOAD HISTORY TO SUPABASE
  // -------------------------
  Future<void> _saveVideoHistory({
    required File videoFile,
    required Uint8List thumbnailBytes,
    required String label,
    required double conf,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        showToast("Bạn chưa đăng nhập!", success: false);
        return;
      }

      final fileId = DateTime.now().millisecondsSinceEpoch;
      final videoName = "$fileId.mp4";
      final thumbName = "$fileId.jpg";

      // UPLOAD VIDEO
      await supabase.storage
          .from("history")
          .uploadBinary(videoName, await videoFile.readAsBytes());
      final videoUrl = supabase.storage.from("history").getPublicUrl(videoName);

      // UPLOAD THUMBNAIL
      await supabase.storage
          .from("history")
          .uploadBinary(thumbName, thumbnailBytes);
      final thumbUrl = supabase.storage.from("history").getPublicUrl(thumbName);

      // INSERT DATABASE
      await supabase.from("jackfruit_video_history").insert({
        "user_id": user.id,
        "video_url": videoUrl,
        "thumbnail_url": thumbUrl,
        "label": label,
        "confidence": conf,
      });

      showToast("Đã lưu lịch sử phân tích video!");
    } catch (e) {
      print("SAVE HISTORY ERROR: $e");
      showToast("Lỗi lưu lịch sử!", success: false);
    }
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),
      appBar: AppBar(
        title: const Text(
          "Phân tích Video / Webcam",
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
            _modeSelector(),
            const SizedBox(height: 20),
            _preview(),
            const SizedBox(height: 8),
            _hintBanner(),
            const SizedBox(height: 20),
            mode == "video" ? _uploadButton() : _webcamButton(),
            const SizedBox(height: 25),
            _resultBox(),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // MODE SELECTOR
  // -------------------------
  Widget _modeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _modeItem("video", Icons.video_file, "Video"),
          _modeItem("webcam", Icons.videocam, "Webcam"),
        ],
      ),
    );
  }

  Widget _modeItem(String id, IconData icon, String label) {
    final active = id == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await _stopWebcam();
          await _stopVideo();

          setState(() {
            mode = id;
            videoPath = null;
            _videoCtrl = null;
            resultMap = {};
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6DBE45) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? Colors.white : Colors.grey[700]),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------
  // PREVIEW
  // -------------------------
  Widget _preview() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6DBE45), width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_cameraCtrl != null &&
              webcamActive &&
              _cameraCtrl!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _cameraCtrl!.value.aspectRatio,
                child: CameraPreview(_cameraCtrl!),
              ),
            )
          else if (_videoCtrl != null &&
              mode == "video" &&
              _videoCtrl!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoCtrl!.value.aspectRatio,
                child: VideoPlayer(_videoCtrl!),
              ),
            )
          else
            const Center(
              child: Icon(Icons.videocam, size: 80, color: Colors.white70),
            ),

          if (analyzingVideo)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------
  // HINT BANNER
  // -------------------------
  Widget _hintBanner() {
    final String text = mode == "video"
        ? "Khi tải video, ứng dụng sẽ phân tích một vài giây.\nVui lòng đợi kết quả."
        : "Webcam liên tục phân tích.\nGiữ máy ổn định để có kết quả tốt.";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF6DBE45), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // UPLOAD VIDEO
  // -------------------------
  Widget _uploadButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        if (!modelLoaded) {
          showToast("Model đang tải...");
          return;
        }

        if (!await _requestVideoPermission()) {
          showToast("Ứng dụng cần quyền đọc video!");
          return;
        }

        final picked = await FilePicker.platform.pickFiles(
          type: FileType.video,
        );
        if (picked == null) return;

        videoPath = picked.files.first.path!;
        await _stopWebcam();
        await _stopVideo();

        _videoCtrl = VideoPlayerController.file(File(videoPath!));
        await _videoCtrl!.initialize();

        setState(() {});
        _videoCtrl!.play();

        setState(() => analyzingVideo = true);
        showToast("Đang phân tích...");

        await _analyzeVideo();

        showToast("Đã phân tích xong!");
        setState(() => analyzingVideo = false);
      },
      icon: const Icon(Icons.upload, color: Colors.white),
      label: const Text("Tải video lên", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6DBE45)),
    );
  }

  // -------------------------
  // ANALYZE VIDEO
  // -------------------------
  Future<void> _analyzeVideo() async {
    if (videoPath == null) return;

    final mid = _videoCtrl!.value.duration.inMilliseconds ~/ 2;

    final bytes = await VT.VideoThumbnail.thumbnailData(
      video: videoPath!,
      imageFormat: VT.ImageFormat.JPEG,
      timeMs: mid,
      quality: 85,
    );

    if (bytes == null) return;

    final frame = img.decodeImage(bytes);
    if (frame == null) return;

    resultMap = await classifier.predictFrame(frame);
    setState(() {});

    // GET BEST RESULT
    final best = resultMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    // SAVE HISTORY INTO DATABASE
    await _saveVideoHistory(
      videoFile: File(videoPath!),
      thumbnailBytes: bytes,
      label: best.key,
      conf: best.value,
    );
  }

  // -------------------------
  // STOP VIDEO
  // -------------------------
  Future<void> _stopVideo() async {
    try {
      await _videoCtrl?.pause();
      await _videoCtrl?.dispose();
    } catch (_) {}

    _videoCtrl = null;
    setState(() {});
  }

  // -------------------------
  // WEBCAM
  // -------------------------
  Widget _webcamButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        if (!webcamActive) {
          _startWebcam();
        } else {
          _stopWebcam();
        }
      },
      icon: Icon(
        webcamActive ? Icons.stop : Icons.videocam,
        color: Colors.white,
      ),
      label: Text(
        webcamActive ? "Dừng Webcam" : "Bắt đầu Webcam",
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: webcamActive ? Colors.red : const Color(0xFF6DBE45),
      ),
    );
  }

  Future<void> _startWebcam() async {
    if (await Permission.camera.request().isDenied) {
      showToast("Cần quyền camera!");
      return;
    }

    final cams = await availableCameras();
    if (cams.isEmpty) {
      showToast("Không tìm thấy camera!");
      return;
    }

    _cameraCtrl = CameraController(
      cams.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraCtrl!.initialize();
    setState(() => webcamActive = true);

    _camTimer = Timer.periodic(const Duration(milliseconds: 900), (_) async {
      if (!webcamActive) return;

      try {
        final pic = await _cameraCtrl!.takePicture();
        final bytes = await pic.readAsBytes();
        final frame = img.decodeImage(bytes);
        if (frame == null) return;

        resultMap = await classifier.predictFrame(frame);
        setState(() {});
      } catch (_) {}
    });

    showToast("Webcam đã bật!");
  }

  Future<void> _stopWebcam() async {
    webcamActive = false;
    _camTimer?.cancel();

    try {
      await _cameraCtrl?.dispose();
    } catch (_) {}

    _cameraCtrl = null;
    setState(() {});
  }

  // -------------------------
  // RESULT BOX
  // -------------------------
  Widget _resultBox() {
    if (resultMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          "Chưa có dữ liệu.\nNhấn tải video lên hoặc bật webcam để phân tích.",
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kết quả phân tích",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _barItem("mit_chin", Colors.amber),
          _barItem("mit_non", Colors.green),
          _barItem("mit_saubenh", Colors.purple),
        ],
      ),
    );
  }

  Widget _barItem(String key, Color color) {
    final v = resultMap[key] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_labelVN(key)}   ${(v * 100).toStringAsFixed(1)}%",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: v,
          color: color,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  String _labelVN(String key) {
    switch (key) {
      case "mit_chin":
        return "Mít chín";
      case "mit_non":
        return "Mít non";
      case "mit_saubenh":
        return "Mít sâu bệnh";
    }
    return key;
  }
}
