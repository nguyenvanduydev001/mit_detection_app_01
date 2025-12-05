import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),

      // KHÔNG DÙNG APPBAR → app nhìn như trang thật
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // Chừa khoảng cách cho đẹp
              // Tiêu đề
              const Text(
                "Giới thiệu hệ thống AgriVision",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6DBE45),
                ),
              ),
              const SizedBox(height: 15),

              Center(child: Image.asset("assets/images/logo.png", height: 150)),
              const SizedBox(height: 20),

              const Text(
                "AgriVision là hệ thống ứng dụng trí tuệ nhân tạo giúp nhận dạng và "
                "phân loại độ chín của trái mít dựa trên hình ảnh. Hệ thống hỗ trợ "
                "nông dân và doanh nghiệp trong việc kiểm tra chất lượng nông sản nhanh chóng.",
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 20),

              const Text(
                "Các tính năng chính:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              feature("Nhận dạng hình ảnh chính xác bằng mô hình AI YOLOv8."),
              feature(
                "Kiểm tra độ chín theo 3 mức: Mít Chín - Mít Sâu Bệnh - Mít Non.",
              ),
              feature("Hỗ trợ chụp ảnh trực tiếp từ Camera/Webcam."),
              feature("Xem biểu đồ thống kê và so sánh kết quả."),
              feature("Trò chuyện với chatbot AgriVision hỗ trợ nông nghiệp."),

              const SizedBox(height: 25),

              const Text(
                "Phiên bản: 1.0.0\nBản quyền © 2025 AgriVision",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF6DBE45)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
