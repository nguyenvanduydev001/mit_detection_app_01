# AgriVision — Mít Detection App (Flutter)

AgriVision là ứng dụng Flutter dùng AI để nhận dạng và phân loại độ chín / tình trạng trái mít từ ảnh và video. Ứng dụng tích hợp Supabase cho authentication, lưu lịch sử và storage; sử dụng TFLite để inference offline và Google Generative API (Gemini) cho chức năng chat phân tích ảnh.

---

## Tóm tắt chức năng chính

| Tính năng | Mô tả ngắn |
|---|---|
| Authentication | Đăng ký / đăng nhập bằng email/password qua Supabase; xác thực email (deep-link) và đổi mật khẩu (re-auth). |
| Phân tích ảnh | Upload / chụp ảnh, phân loại bằng model TFLite (mit_chin / mit_non / mit_saubenh), hiển thị kết quả và lưu lịch sử. |
| Phân tích video / Webcam | Tải video lên (trích frame) hoặc chạy webcam real-time, phân tích frame bằng model, lưu video + thumbnail + kết quả. |
| So sánh mô hình YOLOv8 | Tải CSV kết quả training (results.csv) cho Model A/B, so sánh chỉ số (Precision, Recall, mAP50, mAP50-95), tính F1 và vẽ biểu đồ. |
| Chat AI | Chat với Gemini (Google Generative) — text + gửi ảnh để AI phân tích nông nghiệp / trái mít; lịch sử chat lưu lên Supabase. |
| Thống kê | Hiển thị lịch sử ảnh/video/so sánh; lọc theo nhãn & thời gian; biểu đồ Pie. |
| Quản lý dữ liệu & Cài đặt | Xóa lịch sử chat/ảnh/video/so sánh; QR tải app/dataset; cài đặt thông báo / camera. |

---

## Cấu trúc thư mục chính (chú giải)

| Đường dẫn | Mô tả |
|---|---|
| lib/main.dart | Khởi tạo app, load `.env`, Supabase, deep-link và route chính. |
| lib/supabase_config.dart | Lấy SUPABASE_URL & SUPABASE_ANON_KEY từ `.env`. |
| lib/widgets/custom_input.dart | Component input tái sử dụng (icon, label, toggle hide/show). |
| lib/widgets/menu_item.dart | Component item trong grid menu ở Home. |
| lib/pages/ | Thư mục chứa các màn (pages) — chi tiết bên dưới. |
| lib/services/ | Chứa logic xử lý model TFLite (image/video). |
| lib/chat_storage.dart | Lưu / load tin nhắn chat với Supabase (xử lý blob hex). |
| assets/models/ | Chứa model TFLite và labels.txt. |
| assets/images/ | Logo, QR, thumbnails, ... |
| .env | Biến môi trường: SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY (không commit). |
| pubspec.yaml | Khai báo dependencies & assets. |

---

## Pages (lib/pages) — danh sách và chức năng

| File | Chức năng |
|---|---|
| login_page.dart | Màn đăng nhập (kiểm tra email đã xác thực). |
| register_page.dart | Màn đăng ký (gửi email xác thực). |
| home_page.dart | Dashboard chính: greeting, menu dẫn tới các chức năng. |
| image_page.dart | Upload / chụp ảnh → phân tích bằng TFLite → lưu lịch sử. |
| video_page.dart | Tải video / bật webcam → phân tích frame → lưu lịch sử. |
| chat_page.dart | Giao diện chat AI (text + gửi ảnh), lưu lịch sử chat. |
| compare_page.dart | Tải CSV kết quả YOLOv8 cho Model A/B, so sánh & lưu lịch sử. |
| stat_page.dart | Thống kê dữ liệu, biểu đồ, lịch sử. |
| account_page.dart | Hiển thị thông tin user (email, trạng thái, createdAt), logout. |
| settings_page.dart | Cài đặt app, xóa dữ liệu, QR tải app/dataset, điều hướng đổi mật khẩu. |
| change_password_page.dart | Flow đổi mật khẩu (re-auth + update). |
| about_page.dart | Giới thiệu ứng dụng, tính năng chính. |
| logout_page.dart | Trang đơn giản hiển thị đã đăng xuất. |

---

## Services & Helpers

| File | Vai trò |
|---|---|
| services/jackfruit_classifier.dart | Load model_unquant.tflite, tiền xử lý ảnh (resize 224x224), chạy inference cho ảnh file. |
| services/video_classifier.dart | Load model, xử lý frame ảnh (img.Image) cho video/webcam. |
| chat_storage.dart | Lưu / load / xóa tin nhắn chat trong bảng `chat_messages` trên Supabase. |

---

## Database & Storage (Supabase) — bảng đề xuất

| Tên bảng / bucket | Mục đích / Cột chính |
|---|---|
| Storage bucket: `history` | Lưu ảnh, video, thumbnail. |
| Table: `chat_messages` | (id, user_id, role, text, filename, file_bytes, created_at) — lưu hội thoại & file. |
| Table: `jackfruit_history` | (id, user_id, image_url, label, confidence, created_at) — lịch sử ảnh. |
| Table: `jackfruit_video_history` | (id, user_id, video_url, thumbnail_url, label, confidence, created_at) — lịch sử video. |
| Table: `compare_history` | (id, user_id, model_a json, model_b json, created_at) — lưu lịch sử so sánh. |

Gợi ý: cột `created_at` mặc định = now(); `user_id` liên kết tới auth.users; áp dụng Row-Level Security (RLS) cho bảo mật.

---

## Thư viện chính (packages)

| Package | Mục đích |
|---|---|
| flutter_dotenv | Load biến môi trường từ `.env`. |
| supabase_flutter | Auth, Storage, Database (Supabase). |
| tflite_flutter | Chạy model TFLite trên thiết bị. |
| image | Xử lý ảnh (decode, resize, pixel access). |
| camera | Capture từ camera (webcam). |
| video_player, video_thumbnail | Phát video và trích thumbnail. |
| file_picker | Chọn file (CSV, video, ảnh). |
| fluttertoast / ftoast | Hiển thị toast. |
| fl_chart | Vẽ biểu đồ (Bar, Pie). |
| app_links | Xử lý deep-link (ví dụ: xác thực email). |
| google_generative_ai | Gọi Gemini cho Chat AI. |
| device_info_plus, permission_handler | Kiểm tra phiên bản Android & quyền. |

---

## Hướng dẫn nhanh (Quickstart)

1. Clone repo:
   - git clone <repo-url>
2. Tạo file `.env` ở gốc (KHÔNG commit):
   - SUPABASE_URL=https://...
   - SUPABASE_ANON_KEY=...
   - GEMINI_API_KEY=... (nếu dùng Chat AI)
3. Đảm bảo assets model + labels có sẵn:
   - assets/models/model_unquant.tflite
   - assets/models/labels.txt
   - assets/images/logo.svg, logo.png, qr_app.png, qr_dataset.png
4. Cài dependencies:
   - flutter pub get
5. Chạy app:
   - flutter run
6. Android: khai báo quyền camera / storage / video trong AndroidManifest.xml theo SDK version.

---

## Ghi chú kỹ thuật & khuyến nghị

- Model TFLite hiện dùng input 224x224 và trả về vector scores; labels đọc từ labels.txt. Nếu thay model, cần điều chỉnh tiền xử lý & hậu xử lý tương ứng.
- Hiện bounding box trên image_page là random demo; để chính xác cần dùng model object-detection (YOLOv8) và truyền box thật.
- Chat AI: sử dụng GEMINI_API_KEY và giới hạn kích thước file khi gửi ảnh đến API.
- Bảo mật: không commit `.env`. Thiết lập RLS trên Supabase để đảm bảo người dùng chỉ truy cập dữ liệu của chính họ.
- Xử lý lỗi: Nên thêm logging & retry khi upload thất bại.

---

## Các bước phát triển tiếp theo (gợi ý)

| Ưu tiên | Công việc |
|---|---|
| Cao | Thay bounding box ngẫu nhiên bằng inference object-detection (YOLOv8) để hiển thị box thật. |
| Trung | Thêm unit/integration tests cho services (classifier, chat_storage). |
| Trung | Cải thiện UX cho upload video & webcam (progress, cancel). |
| Thấp | Thêm caching / offline queue để upload khi mạng yếu. |

---

## Phiên bản
- 1.0.0

---

## Nhóm thực hiện
- Nguyễn Văn Duy – 2151220251  
- Lê Nam – 2151220149
