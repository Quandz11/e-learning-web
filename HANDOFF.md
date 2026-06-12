# SKVI E-Learning Platform - Tài Liệu Bàn Giao (Handoff Document)

Tài liệu này được tổng hợp để giúp developer ở phiên làm việc tiếp theo nắm bắt toàn bộ kiến trúc, stack công nghệ và các thành phần của dự án `e-learning-web` một cách nhanh chóng và chính xác.

> **Lưu ý Quan Trọng Về GitNexus:**
> Dự án này sử dụng **GitNexus** để phân tích code. 
> - **LUÔN LUÔN** chạy impact analysis (ví dụ `gitnexus_impact`) trước khi sửa đổi bất kỳ function/class nào.
> - **LUÔN LUÔN** chạy `gitnexus_detect_changes()` trước khi commit.
> - Nếu index báo "stale", hãy chạy lệnh `npx gitnexus analyze` trong terminal.

---

## 1. Tổng Quan Kiến Trúc (Architecture Overview)
Dự án được tổ chức theo mô hình **Monorepo** bao gồm 3 thư mục chính tương ứng với 3 thành phần của hệ thống:
1. `e-learning-server`: Backend phục vụ chung cho cả Web và Mobile.
2. `e-learning-web`: Frontend Web dành cho các Role (Admin, Care, Cabin, Student, Lecturer).
3. `e-learning-mobile`: Mobile App (iOS + Android) dành cho học viên.

---

## 2. e-learning-server (Backend)
- **Công nghệ chính**: ASP.NET Core 8 Web API.
- **Kiến trúc**: Modular Monolith, chia làm các layer:
  - `SKVI.API`: Controllers (Presentation).
  - `SKVI.Application`: Chứa toàn bộ Business Logic. Không code logic ở Controller.
  - `SKVI.Domain`: Entities, Enums.
  - `SKVI.Infrastructure`: Tương tác Database, Bunny (Video), Redis, Email.
  - `SKVI.Shared`: Các class dùng chung, Result, Exception.
- **Database**: SQL Server (Code First qua EF Core).
- **Caching & Realtime**: Redis, SignalR (Chat, Thông báo).
- **Video Hosting/Streaming**: Dùng Bunny.net (Backend chỉ sinh signed URL và lưu metadata, tuyệt đối không stream trực tiếp qua backend).
- **Authentication**: JWT (Access Token) + Refresh Token. Password dùng thuật toán BCrypt. Refresh token được quản lý qua bảng riêng.

*Chi tiết về Database Schema (bảng Users, Roles, Orders, Cabins, Commissions) có sẵn đầy đủ tại `e-learning-server/README.md`.*

---

## 3. e-learning-web (Frontend Web)
- **Công nghệ chính**: ReactJS 19 + Vite + TypeScript.
- **Styling**: `tailwindcss` v4 + `@headlessui/react` (Ghi chú: *Mặc dù README FE ghi là Ant Design, nhưng package.json thực tế đang dùng TailwindCSS và Headless UI*).
- **State Management**: Redux Toolkit (thay vì React Query + Context như README ban đầu).
- **Routing**: React Router v7 (`react-router-dom`).
- **Build/Deploy**: Cấu hình sẵn `Dockerfile` và `nginx.conf`.
- **Cấu trúc thư mục chuẩn**:
  ```text
  src/
  ├── api/
  ├── auth/
  ├── components/
  ├── layouts/
  ├── pages/
  ├── routes/
  └── utils/
  ```

---

## 4. e-learning-mobile (Mobile App)
- **Công nghệ chính**: Flutter (Dart ^3.8.1).
- **State Management**: Riverpod (`flutter_riverpod`).
- **Routing**: `go_router`.
- **Network**: `dio`.
- **Code Generation**: `freezed`, `json_serializable`.
- **Realtime**: `signalr_netcore` (Kết nối websocket về Backend).
- **Cấu hình môi trường**: Quản lý bằng `.env.dev`, `.env.staging`, `.env.prod`.
- **Deep Linking**: Hỗ trợ App Links và Custom URL Scheme (`skvi://`).
  *Lưu ý: Backend hiện đang host file `/.well-known/assetlinks.json` và `apple-app-site-association` để phục vụ App Links.*

---

## 5. Quy trình làm việc (Workflow Khuyến Nghị)
1. **Khám phá Code**: Sử dụng CLI của GitNexus (`npx gitnexus query`, `npx gitnexus context`) để tra cứu luồng execution (execution flows) thay vì dùng `grep` thông thường.
2. **Triển khai Tính năng**:
   - Xem qua thư mục tương ứng của mỗi project (ví dụ Backend -> xem Application Layer).
   - Kiểm tra `package.json` hoặc `pubspec.yaml` hoặc `e-learning-server.sln` để đảm bảo dùng đúng library.
3. **Chạy Project ở Local**:
   - Web: `npm run dev`
   - Mobile: `flutter run`
   - Server: Chạy qua Visual Studio hoặc `dotnet run`.
4. **Deploy**: Có sẵn `docker-compose.yml` tại root cũng như các Dockerfile trong từng sub-folder.

---
*Tài liệu này được update tự động thông qua agent. Dev nhận bàn giao có thể xem chi tiết trong các file README.md con của từng project.*
