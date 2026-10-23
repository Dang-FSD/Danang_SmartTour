# 🌴 DaNang SmartTour AI — Du Lịch Thông Minh Bảo Vệ Kép

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Free%20Tier-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![AI Engine](https://img.shields.io/badge/AI-VokeAPI%20%2F%20Gemini-FF6F00)](https://vokeapi.com)
[![OpenStreetMap](https://img.shields.io/badge/GIS-OpenStreetMap-7EBC6F?logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![SDGs](https://img.shields.io/badge/SDGs-11%20%7C%208%20%7C%2010-blue)](https://sdgs.un.org)

Ứng dụng hướng dẫn viên du lịch thông minh tại Đà Nẵng, Việt Nam với cơ chế cốt lõi **Bảo Vệ Kép (Dual-Layer Protection)**:
1. **Lớp 1: An toàn cá nhân & Tôn giáo** (Halal, Ăn chay, Dị ứng đậu phộng/hải sản, Bệnh lý tim mạch khi trekking/thể thao).
2. **Lớp 2: Điều hướng chống quá tải & Khám phá văn hóa** (Phát hiện Cầu Rồng phun lửa quá tải để tự động đổi tuyến sang Làng đá Non Nước, tạo Thẻ dặn bếp song ngữ cho đầu bếp địa phương).

---

## 📋 Mục lục
- [1. Dữ liệu & Tài nguyên cần chuẩn bị](#1-dữ-liệu--tài-nguyên-cần-chuẩn-bị)
- [2. Cấu hình biến môi trường (.env)](#2-cấu-hình-biến-môi-trường-env)
- [3. Hướng dẫn thiết lập cơ sở dữ liệu (Supabase)](#3-hướng-dẫn-thiết-lập-cơ-sở-dữ-liệu-supabase)
- [4. Cách cài đặt & Chạy ứng dụng Frontend (Flutter)](#4-cách-cài-đặt--chạy-ứng-dụng-frontend-flutter)
- [5. Chạy bộ kiểm thử an toàn (8 Ground-Truth Tests)](#5-chạy-bộ-kiểm-thử-an-toàn-8-ground-truth-tests)
- [6. Chạy thử nghiệm AI Service độc lập (Python)](#6-chạy-thử-nghiệm-ai-service-độc-lập-python)
- [7. Cấu trúc thư mục dự án](#7-cấu-trúc-thư-mục-dự-án)
- [8. Bộ 8 ca kiểm thử an toàn cốt lõi](#8-bộ-8-ca-kiểm-thử-an-toàn-cốt-lõi)
- [9. Xử lý sự cố thường gặp (Troubleshooting)](#9-xử-lý-sự-cố-thường-gặp-troubleshooting)

---

## 1. Dữ liệu & Tài nguyên cần chuẩn bị

Trước khi bắt đầu, các thành viên (collaborators) cần cài đặt sẵn trên máy:
* **Flutter SDK**: Phiên bản stable ≥ `3.24.0` ([Hướng dẫn cài đặt Flutter](https://docs.flutter.dev/get-started/install)).
* **Dart SDK**: Đi kèm cùng Flutter (≥ `3.5.0`).
* **Python 3.10+**: *(Tùy chọn)* Dùng khi cần test các script AI trong thư mục `BE/AI/`.
* **Git**: Quản lý mã nguồn.
* **Tài khoản Supabase** (Miễn phí): Tạo tại [supabase.com](https://supabase.com).
* **Tài khoản VokeAPI**: Lấy API Key tại [vokeapi.com](https://vokeapi.com).

> 💡 **Lưu ý về Dữ liệu Offline:**
> Dự án đã tích hợp sẵn 2 bộ dữ liệu JSON cục bộ:
> - `FE/assets/data/dishes_seed.json` (40 món ăn đặc sản Đà Nẵng kèm bảng thành phần ẩn và cảnh báo nguy cơ).
> - `FE/assets/data/attractions_seed.json` (20 điểm du lịch, di tích văn hóa, trekking và thể thao biển).
> **Ứng dụng có thể chạy mượt mà ngay cả khi chưa kết nối Internet hay chưa cấu hình Supabase!**

---

## 2. Cấu hình biến môi trường (.env)

Dự án sử dụng file `.env` để bảo mật API key. File này đã được thêm vào `.gitignore`.

1. Tạo file `.env` ở thư mục gốc và thư mục `FE/`:
   ```bash
   # Cách 1: Copy từ file mẫu .env.example
   copy .env.example .env
   copy .env.example FE\.env   # Trên Windows CMD / PowerShell
   
   # Hoặc trên Linux / macOS:
   cp .env.example .env
   cp .env.example FE/.env
   ```

2. Mở file `.env` và điền thông tin:
   ```ini
   # 1. VokeAPI Configuration
   VOKE_API_KEY=sk-voke-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   VOKE_BASE_URL=https://api.vokeapi.com/v1
   VOKE_MODEL=deepseek-v4-pro

   # 2. Supabase Configuration
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key-here
   ```

---

## 3. Hướng dẫn thiết lập cơ sở dữ liệu (Supabase)

Nếu bạn muốn kết nối ứng dụng với Database Online trên Cloud:

1. Đăng nhập vào [Supabase Dashboard](https://supabase.com/dashboard) và tạo 1 Project mới.
2. Vào mục **SQL Editor** ở thanh menu bên trái.
3. Mở file `BE/DB/Danang_SmartTour_DB.sql` trong dự án, copy toàn bộ nội dung và paste vào SQL Editor của Supabase.
4. Bấm **RUN** để thực thi script. Script sẽ tự động tạo:
   - Các bảng: `traveler_profiles`, `dishes`, `attractions`, `safety_tickets`.
   - Các ràng buộc bảo mật (Constraints) về Halal, Vegan, Dị ứng, Thể lực tim mạch.
   - Seed data đầy đủ 40 món ăn và 20 địa điểm du lịch Đà Nẵng.
5. Vào **Project Settings** -> **API** để lấy `Project URL` và `anon public key`, sau đó dán vào file `.env`.

---

## 4. Cách cài đặt & Chạy ứng dụng Frontend (Flutter)

### Bước 1: Di chuyển vào thư mục Frontend
```bash
cd FE
```

### Bước 2: Tải các thư viện phụ thuộc (Dependencies)
```bash
flutter pub get
```

### Bước 3: Chạy ứng dụng

#### 🔹 Chạy trên Google Chrome (Nhanh nhất, khuyến nghị khi code giao diện & logic):
```bash
flutter run -d chrome
```

#### 🔹 Chạy trên máy ảo Android (Emulator):
```bash
# Xem danh sách thiết bị đang kết nối
flutter devices

# Chạy trên máy ảo Android đang mở
flutter run -d emulator-5554
# hoặc chỉ định thiết bị
flutter run -d android
```

#### 🔹 Chạy trên Windows Desktop:
```bash
flutter run -d windows
```

---

## 5. Chạy bộ kiểm thử an toàn (8 Ground-Truth Tests)

Để đảm bảo hệ thống không bao giờ bỏ sót dị ứng hoặc rủi ro sức khỏe của du khách, toàn bộ 8 kịch bản an toàn bắt buộc đã được viết thành Unit & Integration Test tự động.

Chạy lệnh sau tại thư mục `FE/`:
```bash
flutter test test/safety_rules_test.dart
```

**Kết quả mong đợi:**
```text
00:01 +8: All tests passed!
```

---

## 6. Chạy thử nghiệm AI Service độc lập (Python)

Nếu bạn phụ trách phần AI và muốn kiểm tra trực tiếp kết nối với VokeAPI (nhận diện món ăn, phân tích thành phần ẩn, tính năng song ngữ):

```bash
# Di chuyển vào thư mục AI
cd BE/AI

# Cài đặt thư viện Python
pip install -r requirements.txt

# Chạy kịch bản test kết nối và đánh giá 8 món ăn
python test_vokeapi.py
```

Kết quả phân tích chi tiết sẽ được xuất ra file `BE/AI/vokeapi_test_results.json`.

---

## 7. Cấu trúc thư mục dự án

```text
DaNang_SmartTour/
├── .env.example             <- Template biến môi trường mẫu
├── .env                     <- File chứa API keys (không commit lên Git)
├── AGENTS.md                <- Quy tắc kỹ thuật, stack và ranh giới an toàn
├── PLAN.md                  <- Kế hoạch chi tiết và tiến độ phát triển
│
├── BE/                      <- BACKEND & AI LAYER
│   ├── DB/
│   │   └── Danang_SmartTour_DB.sql    <- Schema PostgreSQL, Constraints & 60 Records Seed
│   └── AI/
│       ├── requirements.txt           <- Dependencies Python
│       ├── testconnect.py             <- Script kiểm tra VokeAPI cơ bản
│       └── test_vokeapi.py            <- Kịch bản test AI Vision & Reasoning 8 ca an toàn
│
├── FE/                      <- FRONTEND FLUTTER APPLICATION
│   ├── .env                 <- Biến môi trường cục bộ cho Flutter
│   ├── pubspec.yaml         <- Khai báo thư viện & assets Flutter
│   ├── assets/
│   │   └── data/
│   │       ├── dishes_seed.json       <- 40 món ăn (hỗ trợ chạy Offline)
│   │       └── attractions_seed.json  <- 20 điểm du lịch (hỗ trợ chạy Offline)
│   ├── test/
│   │   └── safety_rules_test.dart     <- Bộ test tự động 8 Ground-Truth Cases (100% Pass)
│   └── lib/
│       ├── main.dart                  <- Điểm khởi chạy ứng dụng
│       ├── core/                      <- Tầng Core (Mạng, Cấu hình, Đánh giá an toàn)
│       │   ├── config/                <- EnvConfig, SupabaseConfig (Auto fallback)
│       │   ├── network/               <- VokeClient (AI Chat & Vision Prompts)
│       │   └── utils/                 <- SafetyEvaluator (Quy tắc an toàn), DeeplinkHelper
│       ├── data/                      <- Tầng Dữ liệu (Models, Repositories, Local/Remote)
│       │   ├── models/                <- TravelerProfile, Dish, Attraction, SafetyTicket
│       │   └── datasources/           <- LocalDataSource, SupabaseDataSource
│       └── presentation/              <- Tầng Giao diện (Screens & Widgets)
│           ├── screens/
│           │   ├── home_screen.dart           <- Dashboard tổng quan & Điều hướng 5 Tab
│           │   ├── profile_setup_screen.dart  <- Thiết lập hồ sơ & 4 hồ sơ mẫu (Ali, John...)
│           │   ├── food_scanner_screen.dart   <- Quét AI ảnh món ăn, cảnh báo dị ứng
│           │   ├── chef_ticket_dialog.dart    <- Thẻ dặn đầu bếp song ngữ (Anh - Việt)
│           │   ├── map_explorer_screen.dart   <- Bản đồ OSM, cảnh báo quá tải Cầu Rồng
│           │   └── itinerary_screen.dart      <- Lập lịch trình Agentic với 7 công cụ
│           └── widgets/                       <- Các UI components tái sử dụng
│
└── Documment_Project/       <- Tài liệu dự án gốc (.docx, extracted text)
```

---

## 8. Bộ 8 ca kiểm thử an toàn cốt lõi

Hệ thống được thiết kế theo quy tắc **Zero False-Safe** (thà cảnh báo nhầm còn hơn bỏ sót nguy hiểm):

| STT | Hồ sơ du khách | Tình huống thử nghiệm | Kết quả mong đợi | Hành vi của Hệ thống |
|:---:|:---|:---|:---:|:---|
| **1** | Du khách Hồi giáo (Halal) | Bún chả cá Đà Nẵng | 🔴 **RED** | Phát hiện nước dùng ninh từ xương heo; từ chối và cảnh báo vi phạm Halal. |
| **2** | Tiền sử bệnh tim mạch (Cardiac) | Trekking Mũi Nghê | 🔴 **RED** | Từ chối cung đường dốc đứng hiểm trở; tự động gợi ý cung Voọc Bãi Bắc nhẹ nhàng. |
| **3** | Dị ứng nặng đậu phộng (Peanuts) | Mì Quảng gà | 🟡 **YELLOW** | Phát hiện có đậu phộng rắc mặt; tạo **Thẻ dặn bếp** song ngữ "KHÔNG ĐẬU PHỘNG". |
| **4** | Du khách ăn chay (Vegetarian) | Bánh xèo nấm | 🟢 **GREEN** | Đạt an toàn thuần thực vật; cho phép thêm vào lịch trình. |
| **5** | Mọi du khách | Cầu Rồng quá tải lúc 21h | 🔄 **REROUTE** | Phát hiện mật độ đám đông vượt ngưỡng; tự động điều hướng sang Làng đá Non Nước. |
| **6** | Lỗi kết nối ghi vé (Network Error) | Tạo vé an toàn | ⚠️ **ROLLBACK** | Rollback giao dịch, thông báo mã lỗi và kích hoạt quy trình xác thực lại. |
| **7** | Thể lực tốt, không bệnh lý | Chèo SUP biển Mỹ Khê | 🟢 **GREEN** | Hoàn toàn an toàn; phê duyệt hoạt động thể thao biển. |
| **8** | Món ăn chưa rõ thành phần | Ram bắp (nghi mỡ heo/dầu chiên chung) | 🟡 **YELLOW** | Yêu cầu nhân viên bếp xác nhận dầu chiên riêng trước khi ăn. |

---

## 9. Xử lý sự cố thường gặp (Troubleshooting)

### ❓ Lỗi: `adb: Process exited abnormally with exit code -1073741819`
- **Nguyên nhân**: File `adb.exe` hoặc thư viện `AdbWinApi.dll` trong Android SDK bị lỗi xung đột bộ nhớ trên Windows.
- **Cách khắc phục**:
  1. Tải bản mới nhất của [Android SDK Platform-Tools for Windows](https://dl.google.com/android/repository/platform-tools-latest-windows.zip).
  2. Giải nén và ghi đè vào thư mục:
     `C:\Users\<Tên_User>\AppData\Local\Android\Sdk\platform-tools`
  3. Mở terminal gõ: `adb kill-server` và `adb start-server`.

### ❓ Lỗi: Không thể kết nối Supabase
- **Nguyên nhân**: Chưa điền `SUPABASE_URL` / `SUPABASE_ANON_KEY` trong file `.env`.
- **Cách khắc phục**: Ứng dụng sẽ tự động chuyển sang chế độ **Offline Fallback** (đọc từ `dishes_seed.json` và `attractions_seed.json`). Bạn vẫn test được đầy đủ các tính năng mà không bị crash!

### ❓ Lỗi: VokeAPI không phản hồi
- **Nguyên nhân**: Hết hạn mức hoặc sai API key trong `.env`.
- **Cách khắc phục**: Kiểm tra số dư và trạng thái key tại [vokeapi.com](https://vokeapi.com), hoặc chuyển sang key dự phòng.

---

## 🤝 Đóng góp & Phát triển (Collaboration Guide)
1. Tạo branch mới cho tính năng của bạn: `git checkout -b feature/ten-tinh-nang`.
2. Kiểm tra lỗi lint và format mã nguồn: `flutter analyze`.
3. Chạy toàn bộ test suite: `flutter test`.
4. Commit theo chuẩn Conventional Commits (ví dụ: `feat: add AR route preview`, `fix: handle edge case in allergy evaluator`).
5. Tạo Pull Request để các thành viên khác review!
