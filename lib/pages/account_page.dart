import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

const primaryColor = Color(0xFF6DBE45);

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  String formatDate(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  }

  Future<bool> confirmLogout(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              "Xác nhận đăng xuất",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?",
            ),
            actions: [
              TextButton(
                child: const Text(
                  "Hủy",
                  style: TextStyle(color: Colors.black54),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Đăng xuất"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Thông tin tài khoản",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text("Không tìm thấy người dùng"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: primaryColor.withOpacity(0.25),
                    child: Text(
                      user.email![0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email
                  Text(
                    user.email ?? "",
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Info Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow("User ID", user.id),
                          const Divider(),
                          _infoRow("Email", user.email ?? ""),
                          const Divider(),
                          _infoRow(
                            "Trạng thái",
                            user.emailConfirmedAt == null
                                ? "Chưa xác thực"
                                : "Đã xác thực",
                          ),
                          const Divider(),
                          _infoRow("Tham gia lúc", formatDate(user.createdAt)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Đăng xuất
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await confirmLogout(context);
                      if (!confirm) return;

                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, "/login");
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.logout, color: primaryColor),
                    label: Text(
                      "Đăng xuất",
                      style: TextStyle(color: primaryColor, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
