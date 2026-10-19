# Đánh giá Hệ thống E-Learning SKVI

> Ngày đánh giá: 2026-10-14  
> Người đánh giá: Claude Sonnet 4.6  
> Phạm vi: Toàn bộ monorepo — server (ASP.NET Core), web (React), mobile (Flutter)

---

## 1. Tổng quan kiến trúc

Hệ thống là một **monorepo** gồm 3 sub-project chính:

| Sub-project | Công nghệ | Vai trò |
|---|---|---|
| `e-learning-server` | ASP.NET Core 8, EF Core, SQL Server | REST API + SignalR + Hangfire |
| `e-learning-web` | React 19 + Vite 7 + TypeScript | Web SPA (Azure Static Web Apps) |
| `e-learning-mobile` | Flutter (Dart 3.8) | iOS + Android native app |

**Luồng dữ liệu chính:**
```
Mobile/Web → REST API (/api/*) → SQL Server
           → SignalR (/hubs/*) → realtime
           → Bunny CDN (video/image) → trực tiếp qua signed URL
```

Về mặt thiết kế tổng thể, kiến trúc này **phù hợp** cho một hệ thống e-learning quy mô vừa. Phân tách rõ ràng giữa các tầng, có CDN cho media, và realtime qua SignalR.

---

## 2. Vấn đề cốt lõi: Mobile không load được ảnh/video từ Bunny CDN

Đây là vấn đề có nhiều nguyên nhân tiềm ẩn, phân tích từng lớp:

### 2.1 Cơ chế phát video hiện tại trên mobile

Flutter dùng **hai path** song song:

```
Mobile gọi GET /api/videos/{id}/playback
  → Nhận { playbackUrl (HLS signed), embedUrl (iframe.mediadelivery.net signed) }

Path A — Native player (VideoPlayerController.networkUrl):
  Headers: Referer: https://iframe.mediadelivery.net/
           Origin:  https://iframe.mediadelivery.net
  Phát HLS trực tiếp từ CDN

Path B — WebView embed player:
  Tải embedUrl trong WebView
  Inject JS để ẩn controls Bunny, expose Flutter UI overlay
```

### 2.2 Nguyên nhân khả năng cao nhất: Bunny CDN Referer/Token Restriction

Bunny CDN có tính năng **Allowed Referrers** và **Token Authentication** trên pull zone. Khi bật:

- Trình duyệt desktop gửi `Referer` header → CDN cho phép
- Mobile native player (`VideoPlayerController.networkUrl`) gửi `Referer: https://iframe.mediadelivery.net/` (hard-code trong code) — **đây là giả mạo referrer**. Nếu Bunny kiểm tra referrer policy nghiêm ngặt, request này sẽ bị từ chối.
- Mobile WebView thường gửi `Referer` là blank hoặc origin của WebView — **không khớp** với referrer được phép.

**Bằng chứng trong code** (`media_player_panel.dart`):
```dart
VideoPlayerController.networkUrl(
  Uri.parse(hlsUrl),
  httpHeaders: {
    'Referer': 'https://iframe.mediadelivery.net/',
    'Origin': 'https://iframe.mediadelivery.net',
  },
)
```
Đây là workaround thủ công, không bền vững khi CDN policy thay đổi.

### 2.3 Vấn đề hết hạn token (Token Expiry)

Signed URL cho HLS có expiry **30 phút** (VideoSecurityService). Nếu user:
- Mở app → xem danh sách bài học → để phone idle → quay lại bắt đầu video

→ URL đã hết hạn trước khi được dùng, dẫn đến **403 Forbidden** từ CDN.

**Điểm bất nhất nghiêm trọng:** Hai service khác nhau tạo signed URL với expiry khác nhau:
- `BunnyStreamService.GetEmbedUrl`: expiry **24 giờ**
- `VideoSecurityService.GenerateEmbedUrl`: `AddMinutes(3600)` = **60 giờ** (có thể là lỗi logic — định viết 60 phút?)

Khi `VideoPlaybackController` dùng cả hai, client nhận được `embedUrl` có expiry 60 giờ nhưng `playbackUrl` chỉ 30 phút. Mobile native player dùng `playbackUrl` sẽ hỏng trước.

### 2.4 `CdnTokenKey` bị thiếu trong config

`VideoPlaybackController` đọc `BunnySettings:CdnTokenKey` để sign HMAC-SHA256 cho HLS URL directory. Key này **không tồn tại** trong `appsettings.json` hay `appsettings.Development.json`, dẫn đến:

```
Nếu Bunny pull zone bật URL signing → HLS URL không có chữ ký hợp lệ → 403
```

Code silently skip phần signing khi key null, trả về URL không ký — nhưng CDN vẫn yêu cầu token.

### 2.5 Vấn đề với cached_network_image trên mobile

Flutter dùng `cached_network_image` để load ảnh. Package này cache bằng HTTP headers (`Cache-Control`, `ETag`). Nếu Bunny trả về `Cache-Control: no-store` hoặc ảnh có signed URL ngắn hạn:

- Lần đầu load: OK
- Lần sau: cache key không match URL mới (URL thay đổi mỗi lần sign) → phải re-download liên tục
- Trên mạng yếu/mạng di động: load chậm hoặc timeout

### 2.6 Kiểm tra CORS cho CDN

CDN Bunny (b-cdn.net) không cần CORS từ server SKVI, nhưng WebView Flutter có thể bị chặn bởi **WebView's own CORS policy** nếu trang HTML được inject không khớp origin với CDN resource.

---

## 3. Đánh giá Backend (ASP.NET Core)

### Điểm tốt

- **Kiến trúc phân tầng rõ ràng**: Application/Domain/Infrastructure/Shared — dễ maintain
- **JWT nghiêm ngặt**: ClockSkew zero, session revocation qua `sid` claim, access token 15 phút
- **Rate limiting**: Có built-in, tránh brute force
- **SignalR auth**: Dùng query string token cho WebSocket — đúng cách
- **Soft delete pattern**: Nhất quán qua toàn bộ domain entities
- **Hangfire background jobs**: Phù hợp cho email, notification batch

### Vấn đề cần xử lý

#### 3.1 Secrets trong source code (NGHIÊM TRỌNG)

`appsettings.json` và `appsettings.Development.json` chứa plaintext:
- Bunny API key + VideoTokenKey + StorageApiKey
- JWT Secret key
- SMTP credentials (email + password)
- PayOS API key
- Zalo OTP credentials
- Firebase service account (đã là file riêng nhưng cũng commit)

**Nguy cơ**: Nếu repo bị public hoặc bị leak, toàn bộ hệ thống bị compromise. Cần migrate sang Azure Key Vault hoặc environment variables ngay.

#### 3.2 Hai BunnyService song song gây nhầm lẫn

`BunnyStreamService` và `VideoSecurityService` đều tạo embed/playback URL với logic khác nhau. Không rõ endpoint nào dùng service nào, dẫn đến:
- Expiry không nhất quán (24h vs 60h)
- Khó debug khi URL hỏng
- `VideoPlaybackController` gọi `VideoSecurityService`, trong khi các controller khác có thể gọi `BunnyStreamService`

#### 3.3 Thiếu retry/circuit-breaker cho Bunny API

`BunnyStreamService.SendWithAccessKeyAsync` throw exception ngay khi Bunny trả lỗi. Không có retry policy (Polly). Nếu Bunny tạm thời chậm → upload/stream fail hoàn toàn.

#### 3.4 Video upload giới hạn 2GB trong controller

Hard-code `MaxRequestBodySize = 2L * 1024 * 1024 * 1024`. Không có progress feedback cho client, không resume upload. Với video lớn trên connection không ổn định, upload sẽ fail mà không có thông báo hữu ích.

---

## 4. Đánh giá Web Frontend (React)

### Điểm tốt

- **Redux Toolkit** dùng đúng pattern: slice + thunk rõ ràng
- **Token refresh queue**: Tránh race condition khi nhiều request cùng nhận 401
- **i18n đầy đủ**: vi/en, có fallback
- **CSP headers**: `staticwebapp.config.json` cấu hình đúng cho Bunny CDN
- **SecureVideoPlayer**: Check auth trước khi fetch URL, không expose signed URL trực tiếp

### Vấn đề cần xử lý

#### 4.1 Debug log còn trong production

`LearningPage.tsx:280`:
```js
console.log('DEBUG: currentPart', currentPart)
```
Có thể expose data structure lên browser console của user.

#### 4.2 SecureVideoPlayer không có retry

Khi embed URL fetch fail (network glitch), component chỉ hiện error tĩnh, không tự retry. User phải reload trang.

#### 4.3 `apiClient.ts` dùng raw `fetch` không có timeout

Không có `AbortController` + timeout. Trên mạng yếu, request có thể treo vô thời hạn.

---

## 5. Đánh giá Mobile (Flutter)

### Điểm tốt

- **Riverpod**: State management nhất quán, dễ test
- **AuthInterceptor**: Tự động refresh token trước khi request fail
- **Offline support**: `OfflineDownloadService` check local file trước khi hit network
- **Error recovery**: `_recover()` tự re-fetch signed URL khi 403
- **Cache fallback**: `LearningApi` trả cache khi network fail (UX tốt hơn blank screen)
- **flutter_secure_storage**: Token không lưu SharedPreferences plaintext

### Vấn đề cần xử lý

#### 5.1 Fake subtitle (misleading UX)

`_CaptionOverlay` trong `media_player_panel.dart` hiển thị cue cứng "AI-generated subtitles" — **không phải subtitle thật**. Label "Phụ đề tự động tạo (AI)" sẽ gây nhầm lẫn cho user khi subtitle không khớp nội dung.

#### 5.2 Quality selector là no-op trong embed mode

Khi dùng WebView embed player, user chọn quality (360p/720p/1080p) → snackbar hiện lên → **không có gì xảy ra**. URL không đổi, không gọi API. Đây là false UX, nên ẩn đi hoặc implement đúng.

#### 5.3 Triple postFrameCallback sau fullscreen

```dart
WidgetsBinding.addPostFrameCallback(...)    // lần 1
Future.delayed(200ms, ...)                  // lần 2
Future.delayed(500ms, ...)                  // lần 3
```
Workaround cho WebView re-render timing. Fragile — sẽ hỏng trên thiết bị chậm hoặc khi Flutter thay đổi scheduling. Cần giải pháp event-driven thay vì delay.

#### 5.4 dev và prod cùng backend URL

`.env.dev` và `.env.prod` đều trỏ vào cùng Azure production URL. Không có môi trường staging riêng — mọi test trên dev build đều hit production data.

---

## 6. Bảo mật — Tổng hợp

| Mức độ | Vấn đề |
|---|---|
| 🔴 Nghiêm trọng | Secrets (API keys, JWT secret, SMTP password) commit plaintext vào repo |
| 🔴 Nghiêm trọng | `CdnTokenKey` thiếu trong config → HLS URL không ký → 403 trên CDN nếu signing bật |
| 🟠 Cao | `appsettings.Development.json` dùng production Bunny keys, không có dev CDN riêng |
| 🟠 Cao | `VideoSecurityService.AddMinutes(3600)` có thể là lỗi — định viết 60 phút nhưng ra 60 giờ |
| 🟡 Trung bình | Native HLS player giả mạo `Referer` header — không ổn định khi CDN policy đổi |
| 🟡 Trung bình | Không có Polly retry policy cho Bunny API calls |
| 🟢 Thấp | Debug log `console.log` còn trong LearningPage.tsx |

---

## 7. Khuyến nghị ưu tiên

### Ưu tiên 1 — Fix ngay (blocking issues)

1. **Thêm `CdnTokenKey` vào appsettings** hoặc xác nhận Bunny pull zone không bật URL signing. Nếu bật mà key thiếu → mọi HLS request từ mobile sẽ 403.

2. **Xác nhận expiry intent**: `VideoSecurityService.GenerateEmbedUrl` dùng `AddMinutes(3600)` — nếu muốn 60 phút thì đang sai, nếu muốn 60 giờ thì ghi chú lại. Thống nhất với `BunnyStreamService` (24 giờ).

3. **Kiểm tra Bunny pull zone Allowed Referrers**: Vào Bunny dashboard → pull zone `vz-c90d6c1e-644` → Security → nếu Allowed Referrers bật, thêm blank/empty và mobile app referrer pattern. Hoặc dùng Token Authentication thay vì Referrer restriction.

### Ưu tiên 2 — Bảo mật

4. **Migrate secrets ra khỏi appsettings**: Dùng Azure Key Vault (đã có App Insights nên có Managed Identity) hoặc ít nhất là Azure App Service Environment Variables. Xóa secrets khỏi git history bằng `git filter-repo`.

5. **Tách dev/staging backend**: `.env.dev` không nên trỏ vào production URL. Tạo Azure App Service slot staging hoặc dùng container dev environment.

### Ưu tiên 3 — Cải thiện UX/stability

6. **Hợp nhất hai BunnyService**: Xóa hoặc deprecate `VideoSecurityService`, chỉ dùng `BunnyStreamService` làm single source of truth cho URL generation. Giảm confusion và inconsistency.

7. **Thêm Polly retry cho Bunny HTTP client** trong `Program.cs`:
   ```csharp
   services.AddHttpClient<IBunnyStreamService>()
       .AddTransientHttpErrorPolicy(p => p.WaitAndRetryAsync(3, _ => TimeSpan.FromSeconds(2)));
   ```

8. **Tăng expiry HLS URL hoặc implement pre-fetch**: 30 phút quá ngắn cho user bình thường. Tăng lên 2-4 giờ, hoặc mobile tự-refresh URL 5 phút trước khi hết hạn.

9. **Xóa fake subtitle hoặc implement thật**: Nếu không có real caption, ẩn nút subtitle. Nếu muốn implement, dùng SRT/VTT file từ Bunny Captions API.

10. **Ẩn quality selector trong embed mode**: Tính năng hiện là no-op — gây hiểu nhầm cho user.

---

## 8. Sơ đồ luồng video trên mobile (hiện tại vs đề xuất)

### Hiện tại (có vấn đề)
```
Flutter → GET /api/videos/{id}/playback → Server tạo signed URL (expiry 30 phút)
        → Native player dùng HLS URL với fake Referer header
        → Nếu CDN reject Referer → 403 → _recover() re-fetch → nếu lại 403 → error screen
```

### Đề xuất
```
Flutter → GET /api/videos/{id}/playback → Server tạo signed URL (expiry 2-4 giờ)
        → WebView embed player là primary (Bunny embed tự handle auth)
        → Native player là fallback với proper token auth (không cần Referer spoofing)
        → Background timer: refresh URL khi còn 10 phút expiry
```

---

## 9. Điểm tổng thể

| Tiêu chí | Điểm | Ghi chú |
|---|---|---|
| Kiến trúc tổng thể | 7/10 | Rõ ràng, phân tầng tốt, nhưng có service duplication |
| Bảo mật | 4/10 | Secrets trong repo là vấn đề nghiêm trọng |
| CDN Integration | 5/10 | Logic phân tán, token expiry bất nhất, CdnTokenKey thiếu |
| Mobile UX | 6/10 | Error recovery tốt, nhưng fake features gây misleading |
| Web Frontend | 7/10 | Codebase sạch, CSP đúng, thiếu timeout và retry |
| Backend API | 7/10 | Pattern tốt, cần Polly retry và unified Bunny service |
| **Tổng** | **6/10** | Hệ thống hoạt động được, nhưng có nợ kỹ thuật cần trả |

---

*File này được tạo tự động từ phân tích static code. Các vấn đề runtime cần verify thêm bằng cách test trực tiếp trên thiết bị.*
