import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/widgets/custom_input.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;

  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  // -------------------------------
  // TOAST ĐẸP (premium)
  // -------------------------------
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

  // --------------------------------
  // HANDLE REGISTER
  // --------------------------------
  Future<void> handleRegister() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      showToast("Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    if (pass.length < 6) {
      showToast("Mật khẩu cần ít nhất 6 ký tự!");
      return;
    }

    if (pass != confirm) {
      showToast("Mật khẩu không khớp!", success: false);
      return;
    }

    try {
      await Supabase.instance.client.auth.signUp(email: email, password: pass);

      showToast(
        "Đăng ký thành công! Hãy kiểm tra email để xác thực.",
        success: true,
      );

      Navigator.pushReplacementNamed(context, "/login");
    } catch (e) {
      showToast("Lỗi: $e");
    }
  }

  // --------------------------------
  // UI BUILD
  // --------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 60),
        child: Column(
          children: [
            SvgPicture.asset("assets/images/logo.svg", height: 120),
            const SizedBox(height: 15),

            const Text(
              "AGRI VISION",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6DBE45),
              ),
            ),
            const SizedBox(height: 10),

            CustomInput(
              icon: Icons.email,
              label: "Địa chỉ email",
              hint: "example@gmail.com",
              controller: emailCtrl,
            ),
            const SizedBox(height: 20),

            CustomInput(
              icon: Icons.lock,
              label: "Mật khẩu",
              hint: "Nhập mật khẩu...",
              controller: passCtrl,
              obscure: obscure1,
              onToggleObscure: () => setState(() => obscure1 = !obscure1),
            ),
            const SizedBox(height: 20),

            CustomInput(
              icon: Icons.lock_outline,
              label: "Xác nhận mật khẩu",
              hint: "Nhập lại mật khẩu...",
              controller: confirmCtrl,
              obscure: obscure2,
              onToggleObscure: () => setState(() => obscure2 = !obscure2),
            ),

            const SizedBox(height: 30),

            // Nút đăng ký
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DBE45),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Tạo tài khoản",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, "/login");
                  },
                  child: const Text(
                    "Đăng nhập",
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
    );
  }
}
