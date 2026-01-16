III. YÊU CẦU CHO ĐỘI FRONTEND WEB
1. Stack & Quy ước
Mục	Yêu cầu
Framework	ReactJS + Vite
State	React Query + Context
UI	Ant Design
Auth	JWT (access)
API	Axios instance
Routing	React Router v6
2. Cấu trúc FE
src/
├── api/
├── auth/
├── components/
├── layouts/
├── pages/
├── routes/
├── utils/

3. Các khu vực giao diện bắt buộc
3.1 Auth

Login

Register

Forgot password

3.2 Student Area

Dashboard

My Courses

Video Player (Bunny embed)

Progress tracking

Chat với Care

3.3 Cabin Owner Area

Dashboard doanh thu

Danh sách học viên

Hoa hồng

Rút tiền

3.4 Care Dashboard

Danh sách học viên

Chat realtime

Ghi chú

Upsell

3.5 Lecturer Dashboard

Quản lý khóa học

Upload video

Xem học viên

3.6 Admin Panel

User

Cabin

Course

Order

Commission

Payout approval

4. FE yêu cầu kỹ thuật

Role-based routing

Guard page

Token refresh tự động

Lazy load page

Error boundary