# E-Learning Admin Login Flow

## Setup Environment Variable

Create a `.env` file in `e-learning-web` folder:

```env
VITE_API_URL=http://localhost:5000/api
```

## Server Configuration

Make sure your server (`e-learning-server`) is configured correctly:

### 1. Database Setup
```
ConnectionString: "Server=localhost,1433;Database=ElearningDB;User ID=sa;Password=YourPass@123;..."
```

### 2. JWT Settings (appsettings.json)
```json
{
  "JwtSettings": {
    "Secret": "ReplaceThisWithAStrongSecretKeyAtLeast256BitsLong_SuperSecretKey123!",
    "Issuer": "SKVI_Server",
    "Audience": "SKVI_Client",
    "AccessTokenExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7
  }
}
```

### 3. Run Server
```bash
cd e-learning-server/e-learning-server
dotnet run
```

Server should run on: `http://localhost:5000`

## Web Setup

### 1. Install Dependencies
```bash
cd e-learning-web
npm install
```

### 2. Run Web
```bash
npm run dev
```

Web should run on: `http://localhost:5173`

## Admin Login Flow

### Test Admin Account
To login, you need an ADMIN user in database. You can:

1. **Register as student first** (automatic OTP verification for testing)
2. **Manually update role in database**:
   ```sql
   UPDATE Users SET Role = 'ADMIN' WHERE Email = 'admin@example.com'
   ```

### Or Create Admin via API (if endpoint exists):
```bash
POST http://localhost:5000/api/auth/register
{
  "email": "admin@example.com",
  "password": "SecurePassword123!",
  "fullName": "Admin User",
  "phone": "+84912345678"
}

-- Then verify OTP
POST http://localhost:5000/api/auth/verify-otp
{
  "email": "admin@example.com",
  "otp": "123456"  // See in console [DEV]
}

-- Update role
UPDATE Users SET Role = 'ADMIN' WHERE Email = 'admin@example.com'
```

## Flow Overview

### 1. Login Page (`/login`)
- User enters email & password
- Calls `POST /api/auth/login`
- Server returns `{ accessToken, refreshToken, expiresAt }`
- RefreshToken stored in HttpOnly Cookie (automatic by server)
- AccessToken stored in Memory + localStorage

### 2. Token Storage (Web)
- **Access Token**: Memory (React state) + localStorage (for persistence)
- **Refresh Token**: HttpOnly Cookie (managed by server)

### 3. Admin Dashboard Access (`/admin/dashboard`)
- `ProtectedRoute` checks:
  - Is user authenticated?
  - Does user have ADMIN role?
- If yes → Render dashboard
- If no → Redirect to login

### 4. Token Refresh
- When token expires, app automatically tries to refresh
- `refreshToken()` sends request to `/api/auth/refresh`
- Server validates refreshToken cookie and returns new accessToken

### 5. Logout
- User clicks logout
- Calls `POST /api/auth/logout`
- Server revokes refreshToken
- Clear localStorage & Redux state
- Redirect to login

## Key Features Implemented

✅ **Redux State Management**
- `authSlice` tracks: user, accessToken, expiresAt, isAuthenticated, error

✅ **Auth API Service**
- Centralized API calls with error handling
- JWT token decoding
- Token expiration check

✅ **Protected Routes**
- Check authentication & role-based access

✅ **Token Persistence**
- Auto-restore auth state on page refresh
- Auto-refresh expired tokens

✅ **Error Handling**
- Display error messages on login page
- Console logging for debugging

✅ **Loading States**
- Disable form inputs while loading
- Show loading spinner on button

✅ **Logout Functionality**
- Revoke tokens on server
- Clear client storage
- Redirect to login

## Security Checklist (Following authentication-rules.md)

✅ Password hashing: BCrypt (server-side)
✅ JWT with expiration: 15 minutes
✅ Refresh token rotation: Auto-refresh
✅ Token storage: Memory + HttpOnly Cookie
✅ HTTPS ready: CORS configured with credentials
✅ RBAC: Role checking in ProtectedRoute
✅ Audit: Server logs login attempts
✅ CSRF: Automatic with HttpOnly cookies

## Troubleshooting

### Login fails with "Invalid email or password"
- Check email/password are correct
- Ensure user exists in database
- Verify account is verified (status = ACTIVE)

### Admin dashboard shows "Access Denied"
- Check user role is 'ADMIN' in database
- Clear localStorage and try logging in again

### Token refresh fails
- Check refreshToken is in cookies
- Verify server refreshToken endpoint works
- Check JWT secret is same on server

### CORS errors
- Ensure server CORS policy includes `http://localhost:5173`
- Check `AllowCredentials = true` for cookies

## Next Steps

1. ✅ Create registration flow with OTP verification
2. ✅ Create password reset flow
3. Create user profile page
4. Create role-based dashboards (Student, Instructor, etc.)
5. Add 2FA for admin
6. Add audit logging
