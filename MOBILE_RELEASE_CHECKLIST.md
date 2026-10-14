# Mobile Closed Testing – Release Checklist & Báo cáo

> Ngày: 2026-10-14 · Version hiện tại: `1.0.0+3` · Target: `1.1.0+4`

---

## 1. Tính năng sẵn sàng cho Closed Testing

| Tính năng | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Đăng nhập / Đăng ký / OTP | ✅ Hoàn chỉnh | |
| Quên mật khẩu | ✅ Hoàn chỉnh | |
| Xác thực 2 yếu tố (2FA) | ✅ Hoàn chỉnh | |
| Quản lý hồ sơ (xem, sửa, đổi mật khẩu) | ✅ Hoàn chỉnh | |
| Quản lý phiên đăng nhập & thiết bị | ✅ Hoàn chỉnh | Commit f1db058, 9975225 |
| Trang chủ (Courses, Categories, Articles, Testimonials) | ✅ Hoàn chỉnh | |
| Danh mục khóa học (Learning catalog) | ✅ Hoàn chỉnh | |
| Chi tiết khóa học + Bài học | ✅ Hoàn chỉnh | |
| Phát video (Bunny embed iframe) | ✅ Hoàn chỉnh | Cần backend deploy trước |
| Đọc PDF bài học | ✅ Hoàn chỉnh | Syncfusion |
| Đánh dấu hoàn thành bài học | ✅ Hoàn chỉnh | |
| Chat real-time (SignalR) | ✅ Hoàn chỉnh | |
| Thông báo push (Firebase) | ✅ Hoàn chỉnh | |
| Trang Chính sách riêng tư | ✅ Hoàn chỉnh | |
| **Mua khóa học / Thanh toán** | ❌ Chưa làm | Deferred |
| **Tìm kiếm & bộ lọc** | ❌ Chưa làm | Deferred |
| **Chi tiết bài viết** | ❌ Chưa làm | Deferred |
| **Upload avatar** | ❌ Chưa làm | Deferred |
| **Đăng ký/đăng nhập bằng SĐT** | ❌ Chưa làm | Deferred |

---

## 2. Thay đổi chưa commit (cần commit trước khi build)

Các file đã được tối ưu hiệu năng trong session này, **chưa được commit**:

| File | Thay đổi |
|------|---------|
| `lib/core/network/cache_service.dart` | Thêm TTL validation (mặc định 1 giờ) — cache cũ tự xoá, tránh dữ liệu stale |
| `lib/features/articles/presentation/screens/articles_screen.dart` | Thêm `memCacheWidth: 192, maxWidthDiskCache: 384` cho `CachedNetworkImage` — giảm bộ nhớ |
| `lib/features/home/data/home_repository.dart` | `Future.wait` cho 5 cache reads song song — tăng tốc load offline |
| `lib/features/learning/presentation/screens/learning_screen.dart` | `ListView.builder` thay `Column.map` — tối ưu render danh sách dài |
| `lib/features/learning/presentation/widgets/media_player_panel.dart` | Bỏ phụ đề giả, bỏ quality selector no-op, giảm từ 4 xuống 2 lần reinject WebView |

---

## 3. Checklist trước khi build

### 3.1 Version bump
```yaml
# pubspec.yaml – đổi từ 1.0.0+3 thành:
version: 1.1.0+4
```

### 3.2 Environment – xác nhận `.env.prod`
```
# e-learning-mobile/assets/env/.env.prod
API_BASE_URL=https://skvi-api.azurewebsites.net
```
- Không được để URL dev/staging trong bản prod
- File `.env.prod` **không được commit** (đã có trong `.gitignore`)

### 3.3 Firebase
- Đảm bảo `google-services.json` (Android) đã được đặt tại `android/app/google-services.json`
- File này **không được commit**

### 3.4 Signing keystore (Android)
```
# android/key.properties (không commit)
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../keystore.jks
```
- `android/app/build.gradle` đã cấu hình đọc `key.properties`

### 3.5 Backend dependency — **QUAN TRỌNG**
Trước khi test video, phải deploy backend với các fix đã làm trong session này:
- Bunny CDN URL signing: HLS URL giờ luôn được ký SHA256 (trước đây unsigned → 403)
- Expiry tăng từ 30 phút → 120 phút
- Cần chạy EF Core migration cho các index mới:
  ```bash
  dotnet ef migrations add AddPerformanceIndexes
  dotnet ef database update
  ```

---

## 4. Lệnh build & validation

```bash
# 1. Format check
dart format --output=none --set-exit-if-changed .

# 2. Analyzer
flutter analyze

# 3. Tests
flutter test

# 4. Clean build
flutter clean
flutter pub get

# 5. Build release AAB (khuyến nghị cho Play Console)
flutter build appbundle --release --flavor prod --dart-define=ENV=prod

# Hoặc APK nếu cần upload trực tiếp
flutter build apk --release --flavor prod --dart-define=ENV=prod
```

---

## 5. Upload lên Play Console

1. Vào **Play Console → [App] → Testing → Closed testing**
2. Tạo release mới, upload file `.aab`
3. Điền release notes:

### Release notes (vi-VN) – đề xuất

```
Phiên bản 1.1.0 – Cập nhật tính năng

Tính năng mới:
• Quản lý phiên đăng nhập và thiết bị: xem và thu hồi phiên đăng nhập từ xa
• Bảo mật nâng cao: trực tiếp truy cập "Phiên thiết bị" từ màn hình Cài đặt

Cải tiến hiệu năng:
• Tải trang chủ nhanh hơn nhờ đọc cache song song
• Cuộn danh sách khóa học mượt mà hơn
• Giảm sử dụng bộ nhớ cho hình ảnh bài viết
• Dữ liệu cache tự làm mới sau 1 giờ, tránh hiển thị nội dung cũ

Sửa lỗi:
• Khắc phục lỗi video không load được trên một số thiết bị (403 Forbidden)
• Bỏ tùy chọn phụ đề và chất lượng không hoạt động trong trình phát video
• Màn hình video không bị giật khi thoát chế độ toàn màn hình
```

---

## 6. Rủi ro & lưu ý

| Rủi ro | Mức độ | Xử lý |
|--------|--------|-------|
| Bunny CDN video vẫn 403 nếu backend chưa deploy | **Cao** | Deploy backend + migration trước khi test |
| `google-services.json` sai/thiếu → push notification không hoạt động | **Cao** | Kiểm tra file trước khi build |
| `.env.prod` trỏ sai URL | **Cao** | Verify trước khi build |
| Syncfusion PDF license (free tier) hiển thị watermark | **Trung bình** | OK cho internal testing; cần license trả phí trước release public |
| WebView token inject vẫn dùng 2 lần reinject → đôi khi delay nhẹ | **Thấp** | Chấp nhận được cho closed testing |
| Tính năng thanh toán/mua khóa học chưa có | **Thấp** | Testers đã được thông báo (deferred) |
