import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/widgets/custom_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool obscure = true;

  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  // -------------------------
  // TOAST xịn
  // -------------------------
  void showToast(String message, {bool success = false}) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              style: const TextStyle(color: Colors.black87, fontSize: 16),
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

  // -------------------------
  // Handle Login
  // -------------------------
  Future<void> handleLogin() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showToast("Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: pass,
      );

      final user = res.user;

      if (user == null) {
        showToast("Không tìm thấy người dùng!");
        return;
      }

      if (user.emailConfirmedAt == null) {
        showToast("Email chưa được xác thực! Vui lòng kiểm tra hộp thư.");
        return;
      }

      showToast("Đăng nhập thành công!", success: true);
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      showToast("Sai email hoặc mật khẩu!");
    }
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset("assets/images/logo.svg", height: 120),
              const SizedBox(height: 12),

              const Text(
                "AGRI VISION",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const Text(
                "Ứng dụng nhận dạng và phân loại độ chín trái mít",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 35),

              CustomInput(
                icon: Icons.email,
                label: "Email",
                hint: "example@gmail.com",
                controller: emailCtrl,
              ),
              const SizedBox(height: 20),

              CustomInput(
                icon: Icons.lock,
                label: "Mật khẩu",
                hint: "Nhập mật khẩu...",
                controller: passCtrl,
                obscure: obscure,
                onToggleObscure: () {
                  setState(() => obscure = !obscure);
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DBE45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Đăng nhập",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/register");
                    },
                    child: const Text(
                      "Đăng ký",
                      style: TextStyle(
                        color: Color(0xFF6DBE45),
                        fontWeight: FontWeight.bold,
                      ),
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
