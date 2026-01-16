Dưới đây là CHECKLIST BẮT BUỘC cho Authentication System an toàn:

🔐 I. YÊU CẦU CỐT LÕI (BẮT BUỘC 100%)
1️⃣ Không lưu plaintext password

❌ Cấm tuyệt đối:

Plain password

MD5 / SHA1 / SHA256

✅ Bắt buộc:

BCrypt / Argon2

Có salt

Cost ≥ 10

BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);

2️⃣ Token-based authentication (KHÔNG dùng session cookie)
Chuẩn dùng cho Web + Mobile
Token	Mục đích	Thời gian
Access Token (JWT)	Xác thực API	10–15 phút
Refresh Token	Gia hạn	7–30 ngày
3️⃣ Refresh Token rotation (CỰC KỲ QUAN TRỌNG)

❌ Không được dùng refresh token tĩnh

✅ Bắt buộc:

Mỗi lần refresh → cấp token mới

Token cũ → revoke

📌 Chống:

Token replay

Token leak

4️⃣ Lưu token ĐÚNG CÁCH (KHÁC NHAU THEO PLATFORM)
🌐 Web (React + Vite)
Token	Lưu ở đâu
Access Token	Memory (state)
Refresh Token	HttpOnly Cookie

❌ Không lưu access token vào:

localStorage

sessionStorage

📱 Mobile (Flutter)
Token	Lưu ở đâu
Access Token	Secure Storage
Refresh Token	Secure Storage
5️⃣ HTTPS bắt buộc

❌ Không HTTPS → không deploy

✅:

TLS 1.2+

Redirect HTTP → HTTPS

6️⃣ RBAC – phân quyền nghiêm ngặt

Không dùng if role trong code

Dùng policy

[Authorize(Roles = "Admin")]


Hoặc:

[Authorize(Policy = "InstructorOnly")]

🧠 II. BẢO VỆ CHỐNG TẤN CÔNG PHỔ BIẾN
7️⃣ Chống brute force / credential stuffing

✅ Bắt buộc:

Rate limit login

Lock account tạm thời

Rule	Giá trị
5 lần sai	khóa 15 phút
Captcha	sau 3 lần
8️⃣ Email / Phone verification

Account chưa verify → không cho login

OTP 5–10 phút

9️⃣ 2FA (TOTP) cho role nhạy cảm
Role	Bắt buộc
Admin	✅
Cabin Owner	✅
Instructor	Khuyến nghị
🔍 III. QUẢN LÝ PHIÊN & THIẾT BỊ
🔟 Quản lý session / device

Lưu deviceId

Logout từng thiết bị

Admin revoke toàn bộ

1️⃣1️⃣ Token metadata (rất hay bị bỏ qua)

Refresh token phải lưu:

- TokenHash
- UserId
- DeviceId
- IP
- UserAgent
- ExpiredAt
- RevokedAt


❌ Không lưu token plaintext

🧾 IV. AUDIT & GIÁM SÁT
1️⃣2️⃣ Audit log

Ghi lại:

Login success / fail

Password change

Token refresh

Permission denied

1️⃣3️⃣ Alert bất thường

Login từ IP lạ

Login nhiều thiết bị

Refresh token misuse

🧱 V. API SECURITY CẤU HÌNH
1️⃣4️⃣ Cấu hình JWT chuẩn
Field	Bắt buộc
Issuer	✅
Audience	✅
Signing key	≥ 256-bit
Exp	Bắt buộc
1️⃣5️⃣ CORS strict
AllowedOrigins:
- https://skvi.vn
- https://admin.skvi.vn


❌ Không AllowAnyOrigin

1️⃣6️⃣ CSRF Protection (Web)

Refresh token qua Cookie

Bắt buộc CSRF token

🧠 VI. QUY TẮC CODE BẮT BUỘC CHO TEAM
❌ Không được làm

Token trong localStorage

JWT không expire

Hardcode secret

Log password/token

✅ Phải làm

Secret trong ENV

Auto rotate secret

Config theo ENV

🧩 VII. CHECKLIST NGẮN (CHO REVIEW CODE)

✔ Password hash (BCrypt)
✔ JWT short-lived
✔ Refresh rotation
✔ Token storage đúng platform
✔ HTTPS
✔ RBAC
✔ Rate limit
✔ Audit log
✔ 2FA role nhạy cảm