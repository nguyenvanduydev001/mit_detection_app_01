import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'change_password_page.dart';
import 'chat_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notify = true;
  bool cameraAccess = true;

  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
  }

  void showToast(String message, {bool success = true}) {
    fToast.removeQueuedCustomToasts();

    Widget toast = Container(
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
            color: success ? const Color(0xFF6DBE45) : Colors.red,
            size: 24,
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

  // ⭐ Hiện popup chứa QR
  void showQRDialog(String title, String assetQR) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetQR, width: 220, height: 220),
            const SizedBox(height: 12),
            const Text(
              "Quét QR để tải xuống",
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6DBE45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  // ===== POPUP XÁC NHẬN =====
  Future<bool> confirmDialog(String title) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              "Xác nhận",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text("Bạn có chắc chắn muốn xoá $title không?"),
            actions: [
              TextButton(
                child: const Text(
                  "Hủy",
                  style: TextStyle(color: Colors.black54),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Xoá"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    fToast.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6DBE45),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Cài đặt",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // ================= TÙY CHỌN HỆ THỐNG =================
          const Text(
            "Tùy chọn ứng dụng",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          _buildSwitchTile(
            icon: Icons.notifications_active,
            title: "Thông báo",
            value: notify,
            onChanged: (v) {
              setState(() => notify = v);
              showToast(v ? "Đã bật thông báo" : "Đã tắt thông báo");
            },
          ),

          _buildSwitchTile(
            icon: Icons.camera_alt,
            title: "Quyền truy cập camera",
            value: cameraAccess,
            onChanged: (v) {
              setState(() => cameraAccess = v);
              showToast(v ? "Đã cho phép camera" : "Đã tắt camera");
            },
          ),

          const SizedBox(height: 25),

          // ================= TÀI KHOẢN =================
          const Text(
            "Tài khoản",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          _buildNavTile(
            icon: Icons.lock_reset,
            title: "Đổi mật khẩu",
            color: const Color(0xFF6DBE45),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          ),

          _buildNavTile(
            icon: Icons.security,
            title: "Cài đặt bảo mật",
            color: const Color(0xFF6DBE45),
            onTap: () => showToast("Tính năng đang phát triển", success: false),
          ),

          const SizedBox(height: 25),

          // ================= QUẢN LÝ DỮ LIỆU =================
          const Text(
            "Quản lý dữ liệu",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          _buildNavTile(
            icon: Icons.delete,
            title: "Xóa lịch sử chat",
            color: Colors.red,
            onTap: () async {
              if (await confirmDialog("lịch sử chat")) {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;

                await ChatStorage.clearMessages(user.id);
                showToast("Đã xoá lịch sử chat");
              }
            },
          ),

          _buildNavTile(
            icon: Icons.delete_forever,
            title: "Xóa dữ liệu phân tích hình ảnh",
            color: Colors.red,
            onTap: () async {
              if (await confirmDialog("dữ liệu phân tích hình ảnh")) {
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;

                if (user == null) {
                  showToast("Bạn chưa đăng nhập!", success: false);
                  return;
                }

                try {
                  await supabase
                      .from("jackfruit_history")
                      .delete()
                      .eq("user_id", user.id);

                  showToast("Đã xoá toàn bộ dữ liệu hình ảnh");
                } catch (e) {
                  showToast("Xoá lỗi!", success: false);
                }
              }
            },
          ),

          _buildNavTile(
            icon: Icons.delete_outline,
            title: "Xóa dữ liệu phân tích video",
            color: Colors.red,
            onTap: () async {
              if (await confirmDialog("dữ liệu video")) {
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;
                if (user == null) return;

                await supabase
                    .from("jackfruit_video_history")
                    .delete()
                    .eq("user_id", user.id);

                showToast("Đã xoá lịch sử video");
              }
            },
          ),

          _buildNavTile(
            icon: Icons.delete_sweep,
            title: "Xóa lịch sử so sánh mô hình",
            color: Colors.red,
            onTap: () async {
              if (await confirmDialog("lịch sử so sánh")) {
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;

                if (user == null) return;

                await supabase
                    .from("compare_history")
                    .delete()
                    .eq("user_id", user.id);

                showToast("Đã xoá lịch sử so sánh");
              }
            },
          ),

          const SizedBox(height: 25),

          // ================= THÔNG TIN ỨNG DỤNG =================
          const Text(
            "Tải xuống & Chia sẻ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          // ⭐⭐ QR tải App ⭐⭐
          _buildNavTile(
            icon: Icons.qr_code_2,
            title: "Tải ứng dụng bằng QR",
            color: Color(0xFF6DBE45),
            onTap: () =>
                showQRDialog("Tải xuống ứng dụng", "assets/images/qr_app.png"),
          ),

          // ⭐⭐ QR tải Dataset ⭐⭐
          _buildNavTile(
            icon: Icons.qr_code_scanner,
            title: "Tải bộ dữ liệu mẫu",
            color: Color(0xFF651FFF),
            onTap: () => showQRDialog(
              "Tải bộ dữ liệu test",
              "assets/images/qr_dataset.png",
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Thông tin ứng dụng",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          _buildNavTile(
            icon: Icons.info,
            title: "Giới thiệu AgriVision",
            color: const Color(0xFF6DBE45),
            onTap: () => Navigator.pushNamed(context, "/about"),
          ),

          _buildNavTile(
            icon: Icons.contact_support,
            title: "Hỗ trợ & Liên hệ",
            color: const Color(0xFF6DBE45),
            onTap: () =>
                showToast("Email: agrivision.duy@gmail.com", success: true),
          ),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF6DBE45)),
              title: const Text("Phiên bản ứng dụng"),
              trailing: const Text("v1.0.0"),
            ),
          ),
        ],
      ),
    );
  }

  // ================== UI COMPONENTS ==================
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        dense: true,
        title: Text(title),
        secondary: Icon(icon, color: const Color(0xFF6DBE45)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
