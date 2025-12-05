import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  Map<String, double>? modelA;
  Map<String, double>? modelB;

  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
  }

  // ================== TOAST ==================
  void showToast(String message, {bool success = true}) {
    fToast.removeQueuedCustomToasts();

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(message, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }

  // ================== SAVE HISTORY ==================
  Future<void> saveCompareHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        showToast("Bạn chưa đăng nhập!", success: false);
        return;
      }

      await supabase.from("compare_history").insert({
        "user_id": user.id,
        "model_a": modelA,
        "model_b": modelB,
      });

      showToast("Đã lưu lịch sử so sánh");
    } catch (e) {
      showToast("Lỗi khi lưu!", success: false);
    }
  }

  // ================== PARSE CSV ==================
  double toDouble(String? v) {
    if (v == null) return 0.0;
    return double.tryParse(v.trim()) ?? 0.0;
  }

  Future<Map<String, double>?> parseCSV(Uint8List data) async {
    try {
      final csv = utf8.decode(data);
      final lines = csv.split("\n").where((e) => e.trim().isNotEmpty).toList();

      if (lines.length < 2) return null;

      final header = lines.first.split(",");
      final last = lines.last.split(",");

      Map<String, String> map = {};
      for (int i = 0; i < header.length; i++) {
        map[header[i].trim().toLowerCase()] = (i < last.length)
            ? last[i].trim()
            : "0";
      }

      double p = toDouble(map["metrics/precision(b)"]);
      double r = toDouble(map["metrics/recall(b)"]);
      double map50 = toDouble(map["metrics/map50(b)"]);
      double map5095 = toDouble(map["metrics/map50-95(b)"]);

      double f1 = (p + r == 0) ? 0 : 2 * p * r / (p + r);

      return {
        "precision": p,
        "recall": r,
        "f1": f1,
        "map50": map50,
        "map5095": map5095,
      };
    } catch (e) {
      return null;
    }
  }

  // ================== PICK CSV ==================
  Future<void> pickCSV(bool isA) async {
    final picked = await FilePicker.platform.pickFiles(withData: true);

    if (picked == null || picked.files.first.bytes == null) return;

    final parsed = await parseCSV(picked.files.first.bytes!);

    if (parsed == null) {
      showToast("CSV không hợp lệ!", success: false);
      return;
    }

    setState(() {
      if (isA) {
        modelA = parsed;
        showToast("Model A đã tải ✓");
      } else {
        modelB = parsed;
        showToast("Model B đã tải ✓");
      }
    });

    if (modelA != null && modelB != null) saveCompareHistory();
  }

  // ================== UI TABLE ==================
  Widget buildTable() {
    if (modelA == null || modelB == null) return Container();

    const labels = {
      "precision": "Precision",
      "recall": "Recall",
      "f1": "F1-score",
      "map50": "mAP50",
      "map5095": "mAP50-95",
    };

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.green.shade100),
            children: const [
              Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  "Chỉ số",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  "Model A",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  "Model B",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          ...labels.entries.map(
            (e) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(e.value),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    modelA![e.key]!.toStringAsFixed(4),
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    modelB![e.key]!.toStringAsFixed(4),
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== BAR CHART ==================
  Widget buildChart() {
    if (modelA == null || modelB == null) return Container();

    final metrics = ["precision", "recall", "f1", "map50", "map5095"];
    final labels = ["P", "R", "F1", "m50", "m50-95"];

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(metrics.length, (i) {
            return BarChartGroupData(
              x: i,
              barsSpace: 12,
              barRods: [
                BarChartRodData(
                  toY: modelA![metrics[i]]!,
                  width: 18,
                  color: Colors.green,
                ),
                BarChartRodData(
                  toY: modelB![metrics[i]]!,
                  width: 18,
                  color: Colors.orange,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(labels[v.toInt()]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================== BANNER HƯỚNG DẪN ==================
  Widget buildGuideBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Bạn cần tải file CSV được sinh ra sau khi train YOLOv8.\n\n"
              "📌 Đường dẫn lấy file:\n"
              "→ runs/detect/train*/results.csv\n\n"
              "CSV phải chứa các cột: Precision, Recall, mAP50, mAP50-95.\n"
              "Hệ thống sẽ tự tính F1-score và so sánh 2 mô hình.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    fToast.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6DBE45),
        foregroundColor: Colors.white,
        title: const Text("So sánh mô hình YOLOv8"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildGuideBanner(),

          uploadCard("Tải CSV cho Model A", Colors.green, () => pickCSV(true)),
          const SizedBox(height: 16),
          uploadCard(
            "Tải CSV cho Model B",
            Colors.orange,
            () => pickCSV(false),
          ),

          if (modelA != null && modelB != null) buildTable(),
          if (modelA != null && modelB != null) const SizedBox(height: 16),
          if (modelA != null && modelB != null) buildChart(),
        ],
      ),
    );
  }

  Widget uploadCard(String label, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.upload_file, color: color, size: 32),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
