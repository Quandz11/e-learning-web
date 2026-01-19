. PHẠM VI CHUNG DỰ ÁN
1. Mục tiêu kỹ thuật

Backend dùng chung cho Web & Mobile

Kiến trúc Modular Monolith → sẵn sàng tách Microservice

Hỗ trợ bán khóa học + đa cấp Cabin + hoa hồng tự động

Scale tối thiểu 10.000 user đồng thời

2. Stack công nghệ CHỐT
Layer	Công nghệ
Backend	ASP.NET Core 8 Web API
Auth	JWT + Refresh Token
Database	SSMS
Cache	Redis
Realtime	SignalR
Video	Bunny.net (Storage + CDN + Stream)
Web FE	ReactJS (Vite)
CI/CD	Docker
Cloud	Azure
Monitoring	Azure App Insights
II. YÊU CẦU CHO ĐỘI BACKEND (.NET)
1. Kiến trúc Backend
1.1 Structure bắt buộc
SKVI.Backend
│
├── SKVI.API                // Presentation layer
├── SKVI.Application        // Business logic
├── SKVI.Domain             // Entities, enums
├── SKVI.Infrastructure     // DB, Bunny, Redis, Email
├── SKVI.Shared             // Common, Result, Exception


❌ Không code business logic trong Controller
✅ Controller chỉ gọi Application layer

2. Module bắt buộc phải triển khai
2.1 Auth & User Management

Chức năng

Đăng ký / đăng nhập Email – SĐT

Refresh token

RBAC theo role

2FA cho Admin & Cabin Owner

API

POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/refresh
POST   /api/auth/logout


Yêu cầu kỹ thuật

Password: BCrypt

Token: JWT (15m) + Refresh (7–30 ngày)

Blacklist refresh token khi logout

2.2 User & Role

Roles: ADMIN | CARE | CABIN | STUDENT | LECTURER

Mỗi API phải có [Authorize(Roles=...)]

2.3 Cabin (Đại lý / NPP)

Chức năng

Mua Cabin

Gán học viên/lead

Theo dõi doanh thu & hoa hồng

API

POST   /api/cabins
GET    /api/cabins/{id}/dashboard
GET    /api/cabins/{id}/students

2.4 Lead & Care Management

Chức năng

Import Lead (manual / Zalo API sau)

Gán Lead → Cabin → Care

Theo dõi trạng thái

Status flow

NEW → CONTACTED → CONVERTED → LOST

2.5 Course & Package

Chức năng

CRUD khóa học

Upload video lên Bunny

Curriculum

Bunny integration

Backend chỉ:

Generate signed URL

Save video metadata

❌ Không stream video từ server

2.6 Order & Payment

Chức năng

Checkout

Nhận webhook thanh toán

Active khóa học tự động

Yêu cầu

Payment xử lý idempotent

Webhook verify chữ ký

2.7 Enrollment & Learning

Theo dõi tiến độ học

Chặn truy cập khóa chưa mua

Resume video

2.8 Commission System (Phase 3)

Flow

Order Paid
→ Detect Cabin
→ Create Ledger (PENDING)
→ Admin Approve
→ Payout

2.9 Realtime (SignalR)

Chat Care ↔ Student

Notification:

Thanh toán

Lịch học

Hoa hồng

3. Database & Migration

Dùng EF Core Code First

Migration chạy trong CI/CD

Seed role & admin

4. Logging & Monitoring

Log level: Info / Warning / Error

Global Exception Middleware

App Insights

🧠 I. ĐỊNH NGHĨA ROLE CHUẨN (DÙNG TRONG DB & CODE)
Role	Có tài khoản?	Ghi chú
GUEST / LEAD	❌	Chỉ có Lead record
STUDENT	✅	Đã mua ≥ 1 khóa
CARE	✅	CSKH, tư vấn
CABIN_OWNER	✅	Đại lý/NPP
LECTURER	✅	Tạo nội dung
ADMIN	✅	Vận hành

👉 Guest ≠ User
👉 Guest chỉ tồn tại trong bảng Leads

🧩 II. DATABASE SCHEMA FULL (PRODUCTION)
🔐 A. AUTH & USER
1️⃣ Users
Users (
  Id UUID PK,

  Email VARCHAR(255) UNIQUE,
  Phone VARCHAR(20) UNIQUE,
  PasswordHash TEXT NOT NULL,

  FullName VARCHAR(255),
  AvatarUrl TEXT,

  Role VARCHAR(20) NOT NULL
    CHECK (Role IN ('STUDENT','CARE','CABIN_OWNER','LECTURER','ADMIN')),

  Status VARCHAR(20) DEFAULT 'ACTIVE',
  IsEmailVerified BOOLEAN DEFAULT FALSE,
  IsPhoneVerified BOOLEAN DEFAULT FALSE,

  CreatedAt TIMESTAMP,
  UpdatedAt TIMESTAMP,
  IsDeleted BOOLEAN DEFAULT FALSE
)

2️⃣ RefreshTokens
RefreshTokens (
  Id UUID PK,
  UserId UUID FK REFERENCES Users(Id),

  TokenHash TEXT NOT NULL,
  DeviceId VARCHAR(255),
  IpAddress VARCHAR(50),

  ExpiresAt TIMESTAMP,
  RevokedAt TIMESTAMP,
  CreatedAt TIMESTAMP
)

👥 B. LEAD – ZALO – CARE (KHÁCH FREE)
3️⃣ Leads (Guest)
Leads (
  Id UUID PK,

  FullName VARCHAR(255),
  Phone VARCHAR(20),
  ZaloUserId VARCHAR(255),

  Source VARCHAR(50), -- ZALO, FACEBOOK, MANUAL
  Status VARCHAR(20)
    CHECK (Status IN ('NEW','CONTACTED','CONSULTING','CONVERTED','LOST')),

  AssignedCareId UUID FK REFERENCES Users(Id),
  AssignedCabinId UUID FK REFERENCES Cabins(Id),

  CreatedAt TIMESTAMP,
  UpdatedAt TIMESTAMP
)


📌 Khi lead mua khóa → tạo User(Student) → link LeadId

4️⃣ CareNotes
CareNotes (
  Id UUID PK,
  LeadId UUID,
  StudentId UUID,
  CareId UUID FK REFERENCES Users(Id),

  Note TEXT,
  CreatedAt TIMESTAMP
)

🏢 C. CABIN / ĐẠI LÝ / HOA HỒNG
5️⃣ Cabins
Cabins (
  Id UUID PK,

  Name VARCHAR(255),
  OwnerUserId UUID FK REFERENCES Users(Id),

  CommissionRate DECIMAL(5,2), -- %
  WalletBalance DECIMAL(18,2) DEFAULT 0,

  CreatedAt TIMESTAMP,
  IsActive BOOLEAN DEFAULT TRUE
)

6️⃣ CabinMembers (đa tầng – optional)
CabinMembers (
  Id UUID PK,
  ParentCabinId UUID,
  ChildCabinId UUID,
  Level INT,
  CreatedAt TIMESTAMP
)

🎓 D. COURSE – CONTENT – VIDEO
7️⃣ Courses
Courses (
  Id UUID PK,

  Title VARCHAR(255),
  Description TEXT,

  Price DECIMAL(18,2),
  IsFree BOOLEAN,

  LecturerId UUID FK REFERENCES Users(Id),

  ThumbnailUrl TEXT,
  IsPublished BOOLEAN,

  CreatedAt TIMESTAMP
)

8️⃣ CourseSections
CourseSections (
  Id UUID PK,
  CourseId UUID FK REFERENCES Courses(Id),
  Title VARCHAR(255),
  OrderIndex INT
)

9️⃣ CourseLessons
CourseLessons (
  Id UUID PK,
  SectionId UUID FK REFERENCES CourseSections(Id),

  Title VARCHAR(255),
  Duration INT,

  VideoId UUID FK REFERENCES Videos(Id),

  OrderIndex INT,
  IsPreview BOOLEAN
)

🔟 Videos (Bunny)
Videos (
  Id UUID PK,

  BunnyLibraryId VARCHAR(255),
  BunnyVideoId VARCHAR(255),

  Duration INT,
  CreatedAt TIMESTAMP
)

📚 E. ENROLLMENT – HỌC TẬP
1️⃣1️⃣ Enrollments
Enrollments (
  Id UUID PK,

  StudentId UUID FK REFERENCES Users(Id),
  CourseId UUID FK REFERENCES Courses(Id),

  Progress DECIMAL(5,2),
  EnrolledAt TIMESTAMP,
  CompletedAt TIMESTAMP
)

1️⃣2️⃣ LessonProgress
LessonProgress (
  Id UUID PK,

  EnrollmentId UUID FK REFERENCES Enrollments(Id),
  LessonId UUID FK REFERENCES CourseLessons(Id),

  WatchedSeconds INT,
  IsCompleted BOOLEAN
)

💳 F. THANH TOÁN (MỞ RỘNG ĐƯỢC NHIỀU CỔNG)
1️⃣3️⃣ Orders
Orders (
  Id UUID PK,

  BuyerId UUID FK REFERENCES Users(Id),
  TotalAmount DECIMAL(18,2),

  Status VARCHAR(20)
    CHECK (Status IN ('PENDING','PAID','FAILED','CANCELLED')),

  CreatedAt TIMESTAMP,
  PaidAt TIMESTAMP
)

1️⃣4️⃣ OrderItems
OrderItems (
  Id UUID PK,
  OrderId UUID FK REFERENCES Orders(Id),
  CourseId UUID FK REFERENCES Courses(Id),
  Price DECIMAL(18,2)
)

1️⃣5️⃣ PaymentMethods
PaymentMethods (
  Id UUID PK,
  Code VARCHAR(50), -- VNPAY, VIETQR, BANK, STRIPE
  Name VARCHAR(255),
  IsActive BOOLEAN
)

1️⃣6️⃣ PaymentTransactions
PaymentTransactions (
  Id UUID PK,

  OrderId UUID FK REFERENCES Orders(Id),
  PaymentMethodId UUID FK REFERENCES PaymentMethods(Id),

  ProviderTransactionId VARCHAR(255),
  Amount DECIMAL(18,2),

  Status VARCHAR(20)
    CHECK (Status IN ('INIT','SUCCESS','FAILED')),

  RawPayload JSONB,
  CreatedAt TIMESTAMP
)


📌 VNPay / VietQR / Bank chỉ khác payload

💰 G. COMMISSION – HOA HỒNG
1️⃣7️⃣ CommissionRules
CommissionRules (
  Id UUID PK,
  CabinId UUID,
  CourseId UUID,
  Rate DECIMAL(5,2)
)

1️⃣8️⃣ CommissionLedgers
CommissionLedgers (
  Id UUID PK,

  CabinId UUID FK REFERENCES Cabins(Id),
  OrderId UUID FK REFERENCES Orders(Id),

  Amount DECIMAL(18,2),
  Status VARCHAR(20)
    CHECK (Status IN ('PENDING','APPROVED','PAID')),

  CreatedAt TIMESTAMP
)

1️⃣9️⃣ Payouts
Payouts (
  Id UUID PK,

  CabinId UUID FK REFERENCES Cabins(Id),
  Amount DECIMAL(18,2),

  BankName VARCHAR(255),
  BankAccount VARCHAR(255),

  Status VARCHAR(20),
  PaidAt TIMESTAMP
)

💬 H. CHAT – REALTIME – NOTIFY
2️⃣0️⃣ Chats
Chats (
  Id UUID PK,
  StudentId UUID,
  CareId UUID,
  CreatedAt TIMESTAMP
)

2️⃣1️⃣ ChatMessages
ChatMessages (
  Id UUID PK,
  ChatId UUID FK REFERENCES Chats(Id),
  SenderId UUID,
  Message TEXT,
  CreatedAt TIMESTAMP
)

2️⃣2️⃣ Notifications
Notifications (
  Id UUID PK,
  UserId UUID,
  Title VARCHAR(255),
  Content TEXT,
  IsRead BOOLEAN,
  CreatedAt TIMESTAMP
)

🛡️ I. ADMIN – AUDIT
2️⃣3️⃣ AuditLogs
AuditLogs (
  Id UUID PK,
  UserId UUID,
  Action VARCHAR(255),
  TargetTable VARCHAR(255),
  TargetId UUID,
  Metadata JSONB,
  CreatedAt TIMESTAMP
)

⚡ INDEX BẮT BUỘC

Users(Role)

Leads(Status, AssignedCareId)

Orders(Status, BuyerId)

Enrollments(StudentId, CourseId)

CommissionLedgers(CabinId, Status)


connection string: "Server=localhost,1433;Database=ElearningDB;User Id=sa;Password=YourPass@123;TrustServerCertificate=True"