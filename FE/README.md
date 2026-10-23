# 📱 DaNang SmartTour AI — Frontend (Flutter)

Mobile & Web application for the **DaNang SmartTour AI** project, built using Flutter & Clean Architecture.

> 📖 **HƯỚNG DẪN ĐẦY ĐỦ**: Vui lòng xem file [README.md ở thư mục gốc](../README.md) để biết cách thiết lập môi trường, biến `.env`, cơ sở dữ liệu Supabase và chi tiết 8 kịch bản an toàn.

---

## 🚀 Quick Start (Chạy Nhanh)

### 1. Chuẩn bị biến môi trường
Sao chép `.env.example` thành `.env`:
```bash
copy .env.example .env    # Windows CMD / PowerShell
# cp .env.example .env    # Linux / macOS
```
Điền `VOKE_API_KEY` và thông tin `SUPABASE_*` vào file `.env`. *(Nếu chưa có Supabase, ứng dụng sẽ tự động chạy ở chế độ Offline Fallback)*.

### 2. Cài đặt dependencies
```bash
flutter pub get
```

### 3. Chạy ứng dụng
- **Chạy trên trình duyệt Chrome (khuyên dùng khi phát triển UI & logic)**:
  ```bash
  flutter run -d chrome
  ```
- **Chạy trên máy ảo Android (Pixel 7 / Android Emulator)**:
  ```bash
  flutter run -d emulator-5554
  ```
- **Chạy trên Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

### 4. Chạy bộ kiểm thử an toàn (8 Ground-Truth Cases)
```bash
flutter test
```
Toàn bộ 8 ca kiểm thử cốt lõi (Halal, Cardiac, Peanut Allergy, Vegan, Overload Reroute, v.v.) phải đạt `100% Pass`.
