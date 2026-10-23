# DaNang SmartTour AI — Backend Architecture & Database Documentation

## 1. Tổng quan Kiến trúc Backend (Overview)

DaNang SmartTour AI sử dụng mô hình kết hợp **Backend-as-a-Service (BaaS) qua Supabase Cloud** kết hợp **Edge Services** và **Local Offline Cache**, phục vụ tiêu chí cốt lõi:
- **Tốc độ truy xuất <100ms** cho du khách quốc tế di chuyển liên tục trên địa bàn Đà Nẵng.
- **Chi phí vận hành $0 (Zero Server Costs)** tận dụng gói Supabase Free Tier + VokeAPI Reasoning.
- **Hoạt động ổn định cả khi offline** (rớt mạng tại các vùng hẻo lánh như bán đảo Sơn Trà, rạn Nam Ô).
- **Tuân thủ SDGs**: SDG 11 (thành phố bền vững), SDG 8 (việc làm & kinh tế địa phương), SDG 10 (tiếp cận bình đẳng, hòa nhập).

---

## 2. Cấu trúc Thư mục Backend (`/BE`)

```
BE/
├── AI/                          # Bộ script kiểm thử mô hình suy luận & VokeAPI
│   ├── testconnect.py           # Script test kết nối VokeAPI đa mô hình
│   ├── test_vokeapi.py          # Benchmark độ trễ và độ chính xác JSON payload
│   └── requirements.txt         # Dependencies (requests, python-dotenv)
├── DB/                          # Cơ sở dữ liệu PostgreSQL (Supabase)
│   └── Danang_SmartTour_DB.sql  # Toàn bộ Schema 8 bảng + RLS Policies + 8 Test Cases mẫu
├── README.md                    # Tài liệu kỹ thuật Backend (File này)
└── ROADMAP.md                   # Lộ trình phát triển Backend chi tiết các giai đoạn
```

---

## 3. Thiết kế Cơ sở Dữ liệu (Supabase PostgreSQL Schema)

Cơ sở dữ liệu được thiết kế tối ưu hóa tại [BE/DB/Danang_SmartTour_DB.sql](file:///c:/Vscode/DaNang_SmartTour/BE/DB/Danang_SmartTour_DB.sql), bao gồm 8 bảng phân hệ:

| Bảng | Chức năng | Khóa chính / Khóa ngoại |
|------|-----------|-------------------------|
| `profiles` | Hồ sơ cơ bản của du khách | `id UUID PK`, `display_name`, `fitness_level` ('low', 'moderate', 'high') |
| `health_profiles` | Hồ sơ an toàn y tế, dị ứng & tín ngưỡng | `id SERIAL PK`, `user_id FK`, `allergen`, `diet_rule` ('halal', 'vegan'), `medical_condition` ('heart_disease') |
| `dishes` | Danh mục món ăn Đà Nẵng đã bóc tách nguyên liệu ngầm | `id SERIAL PK`, `name_vi`, `contains_pork`, `contains_peanut`, `is_safe_for_halal`, `requires_kitchen_confirmation` |
| `attractions` | Điểm văn hóa & thể thao Đà Nẵng | `id SERIAL PK`, `name_vi`, `category` ('culture', 'sport'), `difficulty` ('easy', 'moderate', 'hard'), `is_overloaded` |
| `itineraries` | Lịch trình thích ứng đa mục tiêu do AI tạo | `id SERIAL PK`, `user_id FK`, `title`, `status` |
| `itinerary_stops` | Các điểm dừng theo khung giờ kèm cờ an toàn | `id SERIAL PK`, `itinerary_id FK`, `safety_level` ('RED', 'YELLOW', 'GREEN'), `safety_reason` |
| `safety_tickets` | Thẻ cảnh báo song ngữ gửi đầu bếp địa phương | `id SERIAL PK`, `user_id FK`, `ticket_code UNIQUE`, `bilingual_warning`, `verified BOOLEAN` |
| `agent_logs` | Audit log hành vi gọi tool của AI (Zero False-Safe) | `id SERIAL PK`, `user_id FK`, `tool_name`, `success BOOLEAN`, `error_msg` |

---

## 4. Chính sách Bảo mật (Row Level Security - RLS)

Toàn bộ các bảng đều được bật RLS (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) nhằm ngăn chặn việc rò rỉ dữ liệu y tế nhạy cảm của du khách:
- `dishes` & `attractions`: Public read cho toàn bộ du khách ẩn danh.
- `profiles` & `health_profiles`: Cấp quyền `ALL` cho người dùng dựa trên `anon_key` hoặc `auth.uid()`.
- `safety_tickets`: Chỉ cho phép đọc và ghi vé theo `user_id`. Sau khi lưu, Agent bắt buộc gọi hàm kiểm tra `verify_itinerary_status` để bảo đảm cờ an toàn được ghi nhận thành công.

---

## 5. Hướng dẫn Triển khai & Chạy Backend

### 5.1. Khởi tạo Cơ sở Dữ liệu Supabase
1. Đăng nhập [Supabase Dashboard](https://supabase.com).
2. Tạo dự án mới (chọn khu vực `Singapore` để có độ trễ thấp nhất tới Việt Nam).
3. Mở mục **SQL Editor**, sao chép toàn bộ nội dung file [Danang_SmartTour_DB.sql](file:///c:/Vscode/DaNang_SmartTour/BE/DB/Danang_SmartTour_DB.sql) và nhấn **Run**.
4. Truy cập **Project Settings -> API** để lấy `Project URL` và `anon/public key`.

### 5.2. Chạy Kiểm thử Kết nối AI Backend (Python)
```bash
cd BE/AI
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# Chạy test kết nối
python testconnect.py
```
