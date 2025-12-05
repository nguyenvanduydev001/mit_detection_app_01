import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/widgets/menu_item.dart';
import '/pages/image_page.dart';
import '/pages/video_page.dart';
import '/pages/stat_page.dart';
import '/pages/compare_page.dart';
import '/pages/chat_page.dart';
import '/pages/account_page.dart';
import '/pages/about_page.dart';
import '/pages/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Format tiếng Việt
  String formatVietnameseDate(DateTime date) {
    const weekdays = {
      1: "Thứ Hai",
      2: "Thứ Ba",
      3: "Thứ Tư",
      4: "Thứ Năm",
      5: "Thứ Sáu",
      6: "Thứ Bảy",
      7: "Chủ Nhật",
    };

    String weekday = weekdays[date.weekday] ?? "";
    String formatted = DateFormat("dd/MM/yyyy").format(date);

    return "$weekday, $formatted";
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? "Người dùng";

    // 👉 Lấy username (phần trước @)
    final username = email.split('@')[0];

    final dateString = formatVietnameseDate(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===================== HEADER =====================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6DBE45),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    // LEFT TEXT: Xin chào + username
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 👉 Dòng ngang: Xin chào + username
                          Row(
                            children: [
                              const Text(
                                "Xin chào, ",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // 👉 Ngày tháng
                          Text(
                            dateString,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // RIGHT AVATAR
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountPage(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.95),
                        child: Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF6DBE45),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ===================== GRID MENU =====================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.95,
                children: [
                  MenuItem(
                    icon: Icons.image_search,
                    title: "Phân tích ảnh",
                    subtitle: "Upload & nhận dạng",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ImagePage()),
                    ),
                  ),

                  MenuItem(
                    icon: Icons.videocam,
                    title: "Video\nWebcam",
                    subtitle: "Phát hiện real-time",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoPage()),
                    ),
                  ),

                  MenuItem(
                    icon: Icons.chat,
                    title: "Chat\nAgriVision",
                    subtitle: "Tương tác AI",
                    onTap: () {
                      final u = Supabase.instance.client.auth.currentUser;
                      if (u == null) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(userId: u.id),
                        ),
                      );
                    },
                  ),

                  MenuItem(
                    icon: Icons.compare,
                    title: "So sánh\nYOLOv8",
                    subtitle: "Đánh giá model",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComparePage()),
                    ),
                  ),

                  MenuItem(
                    icon: Icons.bar_chart,
                    title: "Thống kê",
                    subtitle: "Hiển thị dữ liệu",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatPage()),
                    ),
                  ),

                  MenuItem(
                    icon: Icons.info,
                    title: "Giới thiệu",
                    subtitle: "Thông tin hệ thống",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    ),
                  ),

                  MenuItem(
                    icon: Icons.person,
                    title: "Tài khoản",
                    subtitle: "Thông tin cá nhân",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountPage()),
                    ),
                  ),

                  MenuItem(
                    icon: Icons.settings,
                    title: "Cài đặt",
                    subtitle: "Tùy chỉnh ứng dụng",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
