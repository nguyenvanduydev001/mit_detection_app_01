import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController controller;
  final VoidCallback? onToggleObscure;

  const CustomInput({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: onToggleObscure != null
                ? InkWell(
                    onTap: onToggleObscure,
                    child: const Icon(Icons.visibility_outlined),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
