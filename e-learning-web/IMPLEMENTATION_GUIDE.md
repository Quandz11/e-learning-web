# Admin Login Flow - Implementation Summary

## 📋 What Was Created

### 1. **Authentication Service** (`src/services/authApi.ts`)
- **Purpose**: Centralized API communication with backend
- **Key Methods**:
  - `login(credentials)` - POST to `/api/auth/login`
  - `verifyOtp(email, otp)` - POST to `/api/auth/verify-otp`
  - `refreshToken()` - POST to `/api/auth/refresh`
  - `logout()` - POST to `/api/auth/logout`
  - `decodeToken(token)` - Decode JWT to extract user info
  - `isTokenExpired(expiresAt)` - Check token validity
- **Features**:
  - Handles credentials with `credentials: 'include'` for cookies
  - Error handling with meaningful messages
  - JWT decoding without external libraries

### 2. **Redux Auth Slice** (`src/store/authSlice.ts`)
- **State Structure**:
  ```typescript
  {
    user: { id, email, fullName, role, avatarUrl },
    accessToken: string,
    expiresAt: string,
    isLoading: boolean,
    error: string | null,
    isAuthenticated: boolean
  }
  ```
- **Actions**:
  - `loginStart()` - Start loading
  - `loginSuccess(payload)` - Set user & tokens
  - `loginFailure(error)` - Handle errors
  - `logout()` - Clear state
  - `setAuthState()` - Restore from persistence
  - `clearError()` - Clear error messages

### 3. **Protected Route Component** (`src/components/ProtectedRoute.tsx`)
- **Purpose**: Guard routes requiring authentication
- **Features**:
  - Check if user is authenticated
  - Verify user has required role
  - Redirect to login if not authorized
  - Usage:
    ```tsx
    <ProtectedRoute requiredRole="ADMIN">
      <AdminDashboardPage />
    </ProtectedRoute>
    ```

### 4. **Updated Login Page** (`src/pages/auth/LoginPage.tsx`)
- **New Features**:
  - Form validation & state management
  - Real login API call
  - Error message display
  - Loading states (disabled inputs, spinner)
  - Password visibility toggle
  - Role-based redirect (ADMIN → `/admin/dashboard`)
  - Token storage in localStorage for persistence

### 5. **Updated App Router** (`src/App.tsx`)
- **New Features**:
  - Protected route for admin dashboard
  - Auto-restore auth state on page load
  - Auto-refresh expired tokens
  - Automatic token refresh with fallback to login

### 6. **Admin Logout Component** (`src/components/admin/AdminHeaderWithLogout.tsx`)
- **Features**:
  - User profile dropdown in header
  - Logout button with server-side token revocation
  - Clear localStorage & Redux state
  - Redirect to login

### 7. **Updated Redux Store** (`src/store/store.ts`)
- Added `authReducer` to store configuration

### 8. **Environment Setup**
- `.env.local` - Local development configuration
- `.env.example` - Template for env variables
- `vite-env.d.ts` - TypeScript types for env variables

### 9. **Documentation**
- `ADMIN_LOGIN_SETUP.md` - Complete setup & flow guide

---

## 🔄 Login Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  User enters email & password on /login                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  POST /api/auth/login with credentials                       │
│  Server validates & returns:                                 │
│  ├─ accessToken (JWT, 15 min expiry)                         │
│  ├─ refreshToken (HTTP-only cookie, 7 day expiry)           │
│  └─ expiresAt (timestamp)                                    │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  Client:                                                      │
│  ├─ Decode JWT to extract user info                          │
│  ├─ Dispatch Redux loginSuccess()                            │
│  ├─ Store accessToken in memory & localStorage              │
│  └─ refreshToken auto-stored in cookie by browser           │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  Check user role:                                            │
│  ├─ ADMIN  → Navigate to /admin/dashboard                   │
│  ├─ STUDENT → Navigate to /dashboard                        │
│  └─ OTHER → Navigate to appropriate page                    │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  Admin Dashboard                                              │
│  ├─ ProtectedRoute checks: isAuthenticated && role=ADMIN    │
│  ├─ Show user profile in header                             │
│  ├─ Display dashboard content                               │
│  └─ On logout: call /api/auth/logout & clear state          │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Implementation

Following `authentication-rules.md`:

✅ **Password Hashing**
- Server uses BCrypt with cost ≥ 10
- Client never sees password

✅ **JWT Tokens**
- AccessToken: 15 minutes (short-lived)
- RefreshToken: 7 days (stored in HttpOnly cookie)
- Both signed with HMAC secret

✅ **Token Storage** (Web)
- **AccessToken**: Memory (Redux state) + localStorage
- **RefreshToken**: HttpOnly Cookie (auto-managed by browser)

✅ **Token Refresh**
- Auto-refresh when token expires
- Automatic token rotation (old token revoked)
- Fallback to login if refresh fails

✅ **HTTPS Ready**
- CORS configured with credentials
- Cookie marked as `Secure` & `SameSite=Strict`

✅ **RBAC (Role-Based Access Control)**
- Check role in ProtectedRoute
- Admin-only dashboard access
- Server validates roles on each request

✅ **Logout**
- Server revokes refreshToken
- Client clears all stored credentials
- User redirected to login

---

## 🚀 How to Test

### Prerequisites
1. Server running on `http://localhost:5000`
2. Database with test admin account

### Step 1: Create Admin User
```bash
# Option A: Register & update role
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "Admin123!",
    "fullName": "Test Admin",
    "phone": "+84912345678"
  }'

# Check console for OTP
# Verify OTP
curl -X POST http://localhost:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "otp": "123456"
  }'

# Then in database:
UPDATE Users SET Role = 'ADMIN' WHERE Email = 'admin@test.com'
```

### Step 2: Start Frontend
```bash
cd e-learning-web
npm install
npm run dev
```

### Step 3: Test Login Flow
1. Go to http://localhost:5173/login
2. Enter: `admin@test.com` / `Admin123!`
3. Click "Log In"
4. Should redirect to `/admin/dashboard`
5. See user profile in header
6. Click user profile → Logout
7. Should redirect back to `/login`

### Step 4: Test Token Persistence
1. Login to admin dashboard
2. Refresh page (F5)
3. Should still be logged in (token restored from localStorage)
4. Check browser DevTools → Application → Cookies → `refreshToken`
5. Check localStorage → `accessToken` & `expiresAt`

---

## 📁 File Structure

```
src/
├── services/
│   └── authApi.ts                    # API calls & JWT handling
├── store/
│   ├── store.ts                      # Redux store configuration
│   └── authSlice.ts                  # Auth state & actions
├── components/
│   ├── ProtectedRoute.tsx            # Route protection wrapper
│   └── admin/
│       ├── AdminHeaderWithLogout.tsx # Header with logout
│       ├── AdminLayout.tsx           # Admin layout wrapper
│       └── ...other components
├── pages/
│   ├── auth/
│   │   ├── LoginPage.tsx             # Updated with login logic
│   │   └── ...other auth pages
│   └── admin/
│       └── AdminDashboardPage.tsx    # Protected admin page
├── App.tsx                           # Updated with routes & auth restore
├── main.tsx                          # Redux provider setup
├── vite-env.d.ts                     # Env types
├── i18n/
│   └── i18n.ts                       # i18n configuration
├── locales/
│   ├── en.json                       # English translations
│   └── vi.json                       # Vietnamese translations
├── .env.local                        # Environment variables (dev)
├── .env.example                      # Env template
└── ADMIN_LOGIN_SETUP.md              # Setup guide
```

---

## 🛠️ Environment Variables

**File**: `.env.local`
```env
VITE_API_URL=http://localhost:5000/api
```

**For Production**: `.env.prod`
```env
VITE_API_URL=https://api.skvi.vn
```

---

## 🔄 Token Refresh Flow

```
User accesses protected resource
         ↓
Check: Is token expired?
         ├─ NO  → Use current token
         └─ YES → POST /api/auth/refresh
                  ├─ Server checks refreshToken cookie
                  ├─ Validates & creates new accessToken
                  └─ Returns new accessToken + expiresAt
                     ├─ Update localStorage
                     ├─ Update Redux state
                     └─ Retry original request
```

---

## 🐛 Debugging Tips

### Check Authentication State
```typescript
// In browser console
localStorage.getItem('accessToken')
localStorage.getItem('expiresAt')
// Check if cookie exists:
document.cookie
```

### Decode JWT
```typescript
// In browser console
import { authApi } from './services/authApi'
authApi.decodeToken(localStorage.getItem('accessToken'))
```

### Network Requests
- Open DevTools → Network tab
- Login and watch requests:
  - `POST /api/auth/login` (200 OK)
  - Verify `refreshToken` cookie is set
  - Check response headers: `Set-Cookie: refreshToken=...`

### Errors
- **"Login failed"** → Check backend is running
- **"Invalid email or password"** → Verify credentials in database
- **"Account is not verified"** → User needs to verify OTP first
- **"CORS error"** → Check server CORS config includes `http://localhost:5173`

---

## 📝 Next Steps

1. ✅ **Admin Login** - DONE
2. **Register Flow** - Implement student registration with OTP
3. **Forgot Password** - Password reset flow
4. **2FA (TOTP)** - 2FA for admin users
5. **Audit Logging** - Log all auth events
6. **Rate Limiting** - Prevent brute force
7. **Profile Management** - Edit user profile
8. **Role-Based Dashboards** - Different dashboards per role

---

## 📚 References

- **Authentication Rules**: `authentication-rules.md`
- **Backend**: `e-learning-server/` folder
- **Frontend**: `e-learning-web/` folder
- **JWT**: https://jwt.io/
- **Redux Toolkit**: https://redux-toolkit.js.org/
- **React Router**: https://reactrouter.com/

---

## ✅ Checklist Before Production

- [ ] Change JWT secret in server (`appsettings.json`)
- [ ] Set `RequireHttpsMetadata = true` in server
- [ ] Update `CORS` policy to production domain
- [ ] Setup database backups
- [ ] Enable HTTPS/SSL
- [ ] Setup environment variables securely
- [ ] Test with production database
- [ ] Setup monitoring & alerting
- [ ] Implement rate limiting
- [ ] Setup audit logging
- [ ] Security audit & penetration testing
