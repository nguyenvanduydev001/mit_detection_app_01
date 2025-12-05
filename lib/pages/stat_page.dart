import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatPage extends StatefulWidget {
  const StatPage({super.key});

  @override
  State<StatPage> createState() => _StatPageState();
}

class _StatPageState extends State<StatPage> {
  List<dynamic> compareHistory = [];
  List<dynamic> imageHistory = [];
  List<dynamic> videoHistory = [];

  bool loading = true;

  // Bộ lọc
  String selectedLabel = "all";
  String selectedTime = "all";

  @override
  void initState() {
    super.initState();
    loadAllHistory();
  }

  // ========================= LOAD DATA ==============================
  Future<void> loadAllHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => loading = false);
        return;
      }

      final compareRes = await supabase
          .from("compare_history")
          .select()
          .eq("user_id", user.id)
          .order("created_at", ascending: false);

      final imageRes = await supabase
          .from("jackfruit_history")
          .select()
          .eq("user_id", user.id)
          .order("created_at", ascending: false);

      final videoRes = await supabase
          .from("jackfruit_video_history")
          .select()
          .eq("user_id", user.id)
          .order("created_at", ascending: false);

      setState(() {
        compareHistory = compareRes;
        imageHistory = imageRes;
        videoHistory = videoRes;
        loading = false;
      });
    } catch (e) {
      debugPrint("LOAD ERROR: $e");
      setState(() => loading = false);
    }
  }

  // ========================= LABEL MAP ==============================
  String mapLabel(String raw) {
    switch (raw) {
      case "mit_chin":
        return "Mít chín";
      case "mit_non":
        return "Mít non";
      case "mit_saubenh":
        return "Mít sâu bệnh";
      default:
        return "Không xác định";
    }
  }

  // ========================= FILTER ==============================
  bool filterByLabel(String raw) {
    if (selectedLabel == "all") return true;
    return raw == selectedLabel;
  }

  bool filterByTime(String rawTime) {
    if (selectedTime == "all") return true;

    final date = DateTime.parse(rawTime).toLocal();
    final now = DateTime.now();

    if (selectedTime == "today") {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }
    if (selectedTime == "7d") {
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }
    if (selectedTime == "30d") {
      return date.isAfter(now.subtract(const Duration(days: 30)));
    }

    return true;
  }

  // ========================= SECTION TITLE ==============================
  Widget sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ========================= BUILD IMAGE CARD ===========================
  Widget buildImageCard(Map item) {
    if (!filterByLabel(item["label"]) || !filterByTime(item["created_at"])) {
      return Container();
    }

    final label = mapLabel(item["label"]);
    final conf = ((item["confidence"] ?? 0.0) * 100).toStringAsFixed(1);
    final imageUrl = item["image_url"];

    final time = DateFormat(
      "dd/MM/yyyy - HH:mm",
    ).format(DateTime.parse(item["created_at"]).toLocal());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text("Độ tin cậy: $conf%"),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= BUILD VIDEO CARD ===========================
  Widget buildVideoCard(Map item) {
    if (!filterByLabel(item["label"]) || !filterByTime(item["created_at"])) {
      return Container();
    }

    final label = mapLabel(item["label"]);
    final conf = ((item["confidence"] ?? 0.0) * 100).toStringAsFixed(1);
    final thumb = item["thumbnail_url"];

    final time = DateFormat(
      "dd/MM/yyyy - HH:mm",
    ).format(DateTime.parse(item["created_at"]).toLocal());

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                thumb,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text("Độ tin cậy: $conf%"),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= COMPARE CARD (UI bảng đẹp) ===========================
  Widget buildCompareCard(Map record) {
    final time = DateFormat(
      "dd/MM/yyyy - HH:mm",
    ).format(DateTime.parse(record["created_at"]).toLocal());

    final modelA = record["model_a"];
    final modelB = record["model_b"];

    double getV(v) => (v ?? 0).toDouble();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.history, color: Color(0xFF6DBE45)),
                SizedBox(width: 8),
                Text(
                  "Lịch sử so sánh",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(time, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),

            // Bảng số liệu đẹp như hình bạn gửi
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                _headerRow(),
                _dataRow(
                  "Precision",
                  getV(modelA["precision"]),
                  getV(modelB["precision"]),
                ),
                _dataRow(
                  "Recall",
                  getV(modelA["recall"]),
                  getV(modelB["recall"]),
                ),
                _dataRow("F1-score", getV(modelA["f1"]), getV(modelB["f1"])),
                _dataRow("mAP50", getV(modelA["map50"]), getV(modelB["map50"])),
                _dataRow(
                  "mAP50-95",
                  getV(modelA["map5095"]),
                  getV(modelB["map5095"]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.green.shade100),
      children: const [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text("Chỉ số", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: Text("Model A", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: Text("Model B", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  TableRow _dataRow(String label, double a, double b) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(label)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            a.toStringAsFixed(3),
            style: const TextStyle(color: Colors.green),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            b.toStringAsFixed(3),
            style: const TextStyle(color: Colors.orange),
          ),
        ),
      ],
    );
  }

  // ========================= PIE CHART ===========================
  Widget buildPieChart() {
    final counts = {"mit_chin": 0, "mit_non": 0, "mit_saubenh": 0};

    for (var e in [...imageHistory, ...videoHistory]) {
      if (filterByTime(e["created_at"])) {
        counts[e["label"]] = (counts[e["label"]] ?? 0) + 1;
      }
    }

    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("Không có dữ liệu để biểu đồ."),
      );
    }

    return SizedBox(
      height: 230,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.amber,
              title: "${counts["mit_chin"]}",
              value: counts["mit_chin"]!.toDouble(),
              radius: 55,
            ),
            PieChartSectionData(
              color: Colors.green,
              title: "${counts["mit_non"]}",
              value: counts["mit_non"]!.toDouble(),
              radius: 55,
            ),
            PieChartSectionData(
              color: Colors.purple,
              title: "${counts["mit_saubenh"]}",
              value: counts["mit_saubenh"]!.toDouble(),
              radius: 55,
            ),
          ],
        ),
      ),
    );
  }

  // ========================= FILTER UI ===========================
  Widget buildFilters() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedLabel,
                    items: const [
                      DropdownMenuItem(
                        value: "all",
                        child: Text("Tất cả loại mít"),
                      ),
                      DropdownMenuItem(
                        value: "mit_chin",
                        child: Text("Mít chín"),
                      ),
                      DropdownMenuItem(
                        value: "mit_non",
                        child: Text("Mít non"),
                      ),
                      DropdownMenuItem(
                        value: "mit_saubenh",
                        child: Text("Mít sâu bệnh"),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedLabel = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedTime,
                    items: const [
                      DropdownMenuItem(
                        value: "all",
                        child: Text("Tất cả thời gian"),
                      ),
                      DropdownMenuItem(value: "today", child: Text("Hôm nay")),
                      DropdownMenuItem(
                        value: "7d",
                        child: Text("7 ngày gần đây"),
                      ),
                      DropdownMenuItem(
                        value: "30d",
                        child: Text("30 ngày gần đây"),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedTime = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================= PAGE UI ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6DBE45),
        centerTitle: true,
        title: const Text(
          "Thống kê dữ liệu",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6DBE45)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                sectionTitle("Bộ lọc thống kê", Icons.filter_alt),
                buildFilters(),

                sectionTitle("Biểu đồ tổng quát", Icons.pie_chart),
                buildPieChart(),
                const SizedBox(height: 20),

                sectionTitle("Lịch sử phân tích hình ảnh", Icons.image),
                ...imageHistory.map((e) => buildImageCard(e)).toList(),

                sectionTitle("Lịch sử phân tích video", Icons.videocam),
                ...videoHistory.map((e) => buildVideoCard(e)).toList(),

                sectionTitle(
                  "Lịch sử so sánh mô hình YOLOv8",
                  Icons.auto_graph,
                ),
                ...compareHistory.map((e) => buildCompareCard(e)).toList(),
              ],
            ),
    );
  }
}
