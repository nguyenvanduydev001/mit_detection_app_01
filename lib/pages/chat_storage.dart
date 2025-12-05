import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatStorage {
  static final _db = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> loadMessages(String userId) async {
    final res = await _db
        .from("chat_messages")
        .select()
        .eq("user_id", userId)
        .order("created_at", ascending: true);

    Uint8List? decodeHex(String? hex) {
      if (hex == null) return null;

      // Supabase trả về dạng: \xAB12CD
      hex = hex.replaceFirst(r'\x', '');

      final length = hex.length;
      final bytes = <int>[];

      for (int i = 0; i < length; i += 2) {
        final part = hex.substring(i, i + 2);
        bytes.add(int.parse(part, radix: 16));
      }

      return Uint8List.fromList(bytes);
    }

    return res.map((e) {
      return {
        "role": e["role"],
        "text": e["text"],
        "filename": e["filename"],
        "file": decodeHex(e["file_bytes"]),
      };
    }).toList();
  }

  static Future<void> saveMessage(
    String userId,
    String role,
    String text, {
    List<int>? fileBytes,
    String? filename,
  }) async {
    await _db.from("chat_messages").insert({
      "user_id": userId,
      "role": role,
      "text": text,
      "filename": filename,
      "file_bytes": fileBytes != null ? Uint8List.fromList(fileBytes) : null,
    });
  }

  static Future<void> clearMessages(String userId) async {
    await _db.from("chat_messages").delete().eq("user_id", userId);
  }
}
