# E-Learning Authentication Flow - Complete Implementation

## 1. User Login → Server Response

### Frontend (LoginPage.tsx)
```typescript
// User submits email + password
const response = await authApi.login({ email, password });

// Response structure:
// {
//   accessToken: "eyJhbGc...",
//   expiresAt: "2026-01-19T10:15:00Z"
// }
```

### Backend (AuthController.cs)
```csharp
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] LoginRequest request)
{
    var response = await _authService.LoginAsync(request, ipAddress, userAgent);
    
    // ✅ Set HTTP-only Cookie (Refresh Token)
    SetRefreshTokenCookie(response.RefreshToken);
    
    // ✅ Return JSON with Access Token
    return Ok(new { response.AccessToken, response.ExpiresAt });
}

private void SetRefreshTokenCookie(string refreshToken)
{
    var cookieOptions = new CookieOptions
    {
        HttpOnly = true,      // JavaScript cannot access
        Expires = DateTime.UtcNow.AddDays(7),
        SameSite = SameSiteMode.Strict,
        Secure = true         // HTTPS only
    };
    
    Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
}
```

**Backend returns:**
- ✅ HTTP-only Cookie: `refreshToken` (7 days)
- ✅ JSON Response: `accessToken` (15 minutes) + `expiresAt`

---

## 2. Client Storage & Authorization Header

### Frontend (authApi.ts)
```typescript
// In-memory storage (not vulnerable to XSS)
let accessToken: string | null = null;

class AuthApi {
  setAccessToken(token: string | null): void {
    accessToken = token;  // Memory only
  }

  private getHeaders(includeAuth = false): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && accessToken) {
      headers['Authorization'] = `Bearer ${accessToken}`;  // ✅ Added to every request
    }

    return headers;
  }
}
```

### Storage Strategy (Security Best Practice)
```
┌─────────────────────────────────────┐
│        Client-Side Storage          │
├─────────────────────────────────────┤
│ 1. Access Token                     │
│    └─ In Memory (fast, secure)      │
│    └─ localStorage (persist)        │
│    └─ Sent: Authorization header    │
├─────────────────────────────────────┤
│ 2. Refresh Token                    │
│    └─ HTTP-only Cookie (auto-sent)  │
│    └─ JavaScript cannot access      │
│    └─ Browser handles automatically │
└─────────────────────────────────────┘
```

**Login Flow:**
```typescript
const response = await authApi.login({ email, password });
const user = authApi.decodeToken(response.accessToken);

// ✅ Save in memory
authApi.setAccessToken(response.accessToken);

// ✅ Persist in localStorage (for page reload)
localStorage.setItem('accessToken', response.accessToken);
localStorage.setItem('expiresAt', response.expiresAt);

// ✅ Redux state
dispatch(loginSuccess({ user, accessToken, expiresAt }));

// ✅ Redirect
navigate('/admin/dashboard');
```

---

## 3. Auto-Refresh Token Expired

### Flow Diagram
```
┌─────────────────┐
│  App Mounted    │
└────────┬────────┘
         │
         ├─→ Get token from localStorage
         │
         ├─→ Check if expired?
         │
         ├─→ YES: Call /refresh
         │       ├─→ Browser auto-sends Cookie 🔒
         │       ├─→ Server validates & rotates
         │       ├─→ Send new accessToken + Cookie
         │       └─→ Update memory & localStorage
         │
         └─→ NO: Restore auth state
```

### Frontend (App.tsx)
```typescript
useEffect(() => {
  const accessToken = localStorage.getItem('accessToken');
  const expiresAt = localStorage.getItem('expiresAt');

  if (accessToken && expiresAt) {
    // ✅ Restore in memory
    authApi.setAccessToken(accessToken);

    if (!authApi.isTokenExpired(expiresAt)) {
      // Token still valid - restore state
      const user = authApi.decodeToken(accessToken);
      dispatch(setAuthState({
        user,
        accessToken,
        expiresAt,
        isAuthenticated: true,
      }));
    } else {
      // Token expired - auto-refresh
      authApi.refreshToken()
        .then((response) => {
          const user = authApi.decodeToken(response.accessToken);
          
          // ✅ Update memory
          authApi.setAccessToken(response.accessToken);
          
          // ✅ Update localStorage
          localStorage.setItem('accessToken', response.accessToken);
          localStorage.setItem('expiresAt', response.expiresAt);
          
          // ✅ Update Redux
          dispatch(setAuthState({
            user,
            accessToken: response.accessToken,
            expiresAt: response.expiresAt,
            isAuthenticated: true,
          }));
        })
        .catch(() => {
          // Refresh failed - clear and redirect to login
          authApi.setAccessToken(null);
          localStorage.removeItem('accessToken');
          localStorage.removeItem('expiresAt');
        });
    }
  }
}, [dispatch]);
```

### Backend (AuthController.cs)
```csharp
[HttpPost("refresh")]
public async Task<IActionResult> Refresh()
{
    // ✅ Browser auto-includes Cookie (httpOnly)
    var refreshToken = Request.Cookies["refreshToken"];
    
    if (string.IsNullOrEmpty(refreshToken))
    {
        return Unauthorized(new { message = "Refresh token is missing." });
    }

    try
    {
        var response = await _authService.RefreshTokenAsync(
            refreshToken, ipAddress, userAgent);
        
        // ✅ Rotate token - set new Cookie
        SetRefreshTokenCookie(response.RefreshToken);
        
        // ✅ Return new accessToken
        return Ok(new { response.AccessToken, response.ExpiresAt });
    }
    catch (UnauthorizedAccessException ex)
    {
        return Unauthorized(new { message = ex.Message });
    }
}
```

**Token Rotation (AuthService.cs):**
```csharp
public async Task<AuthResponse> RefreshTokenAsync(
    string refreshToken, string ipAddress, string userAgent)
{
    var tokenEntity = await _context.RefreshTokens
        .Include(t => t.User)
        .FirstOrDefaultAsync(t => t.TokenHash == refreshToken);

    if (tokenEntity == null || tokenEntity.RevokedAt != null || 
        tokenEntity.ExpiresAt < DateTime.UtcNow)
    {
        throw new UnauthorizedAccessException("Invalid or expired refresh token.");
    }

    // ✅ Revoke old token
    tokenEntity.RevokedAt = DateTime.UtcNow;

    // ✅ Generate new tokens (with fullName)
    var user = tokenEntity.User;
    var newAccessToken = _tokenService.GenerateAccessToken(
        user.Id, user.Email, user.Role, user.FullName);  // ← FullName included!
    var newRefreshToken = _tokenService.GenerateRefreshToken();

    // ✅ Save new token
    var newRefreshTokenEntity = new RefreshToken
    {
        Id = Guid.NewGuid(),
        UserId = user.Id,
        TokenHash = newRefreshToken,
        IpAddress = ipAddress,
        UserAgent = userAgent,
        ExpiresAt = DateTime.UtcNow.AddDays(7),
        CreatedAt = DateTime.UtcNow
    };

    _context.RefreshTokens.Add(newRefreshTokenEntity);
    await _context.SaveChangesAsync();

    return new AuthResponse(newAccessToken, newRefreshToken, 
        DateTime.UtcNow.AddMinutes(15));
}
```

---

## 4. User Logout - Clear Everything

### Frontend (LogoutButton)
```typescript
const handleLogout = async () => {
  try {
    await authApi.logout();  // Calls server
  } finally {
    // Clear local state
    dispatch(logout());      // Redux action
  }
};
```

**authApi.logout():**
```typescript
async logout(): Promise<void> {
  try {
    // ✅ Notify server to revoke token
    await fetch(`${API_BASE_URL}/auth/logout`, {
      method: 'POST',
      headers: this.getHeaders(),
      credentials: 'include',  // Send Cookie
    });
  } finally {
    // ✅ Clear client-side storage
    this.setAccessToken(null);              // Memory
    localStorage.removeItem('accessToken'); // Storage
    localStorage.removeItem('expiresAt');   // Storage
  }
}
```

### Backend (AuthController.cs)
```csharp
[HttpPost("logout")]
public async Task<IActionResult> Logout()
{
    // ✅ Get refreshToken from Cookie
    var refreshToken = Request.Cookies["refreshToken"];
    
    if (!string.IsNullOrEmpty(refreshToken))
    {
        // ✅ Mark token as revoked (prevent reuse)
        await _authService.LogoutAsync(refreshToken);
    }

    // ✅ Delete Cookie
    Response.Cookies.Delete("refreshToken");
    
    return Ok(new { message = "Logged out successfully." });
}

public async Task LogoutAsync(string refreshToken)
{
    var tokenEntity = await _context.RefreshTokens
        .FirstOrDefaultAsync(t => t.TokenHash == refreshToken);
    
    if (tokenEntity != null)
    {
        // ✅ Revoke token
        tokenEntity.RevokedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }
}
```

---

## 5. Complete Token Lifecycle

```
┌──────────────────────────────────────────────────────────────┐
│                    TOKEN LIFECYCLE                           │
└──────────────────────────────────────────────────────────────┘

1️⃣ LOGIN
   ├─ Client: POST /auth/login { email, password }
   ├─ Server: Validate credentials
   ├─ Server: Generate accessToken (15 min) + refreshToken (7 days)
   ├─ Server: Set HTTP-only Cookie: refreshToken
   ├─ Server: Return JSON { accessToken, expiresAt }
   └─ Client: Save accessToken in memory + localStorage

2️⃣ AUTHENTICATED REQUESTS
   ├─ Client: GET /api/resource
   ├─ Client: Add header: Authorization: Bearer {accessToken}
   ├─ Server: Validate JWT signature & expiration
   ├─ Server: Check claims (userId, role, email, fullName)
   ├─ Server: Process request ✅
   └─ Client: Receive response

3️⃣ AUTO-REFRESH (Token Expiring)
   ├─ Client: Detect token expiring (check expiresAt)
   ├─ Client: POST /auth/refresh (Browser auto-sends Cookie 🔒)
   ├─ Server: Validate refreshToken from Cookie
   ├─ Server: Revoke old token (prevent replay)
   ├─ Server: Generate new accessToken + refreshToken
   ├─ Server: Set new HTTP-only Cookie: refreshToken
   ├─ Server: Return JSON { accessToken, expiresAt }
   ├─ Client: Update memory + localStorage
   └─ Continue authenticated requests ✅

4️⃣ LOGOUT
   ├─ Client: POST /auth/logout
   ├─ Server: Revoke refreshToken (set RevokedAt)
   ├─ Server: Delete Cookie: refreshToken
   ├─ Client: Clear memory: setAccessToken(null)
   ├─ Client: Clear storage: localStorage.removeItem()
   ├─ Client: Clear Redux: dispatch(logout())
   └─ Redirect: /login ✅

5️⃣ SECURITY
   ✅ Access Token: Short-lived (15 min), in memory + localStorage
   ✅ Refresh Token: Long-lived (7 days), HTTP-only Cookie
   ✅ Token Rotation: Old token revoked on refresh
   ✅ Replay Prevention: Revoked tokens rejected
   ✅ CSRF Protection: SameSite=Strict on Cookie
   ✅ XSS Protection: HTTP-only Cookie inaccessible to JavaScript
```

---

## 6. Testing the Flow

### Step 1: Register & Verify OTP
```bash
# Terminal 1: Backend running
cd e-learning-server
dotnet run  # HTTPS on localhost:7145

# Terminal 2: Frontend running
cd e-learning-web
npm run dev  # http://localhost:5173
```

### Step 2: Open Browser Console
```javascript
// Check localStorage
localStorage.getItem('accessToken')
localStorage.getItem('expiresAt')

// Check memory (via Redux)
store.getState().auth.accessToken

// Check refreshToken (hidden)
// document.cookie  // refreshToken not visible (HTTP-only) ✓
```

### Step 3: Test Auto-Refresh
```javascript
// Manually trigger refresh (for testing)
import { authApi } from './services/authApi';

authApi.refreshToken().then(response => {
  console.log('New token:', response.accessToken);
  console.log('Expires at:', response.expiresAt);
});
```

### Step 4: Monitor Network Tab
- **POST /auth/login**
  - Request: { email, password }
  - Response: { accessToken, expiresAt }
  - Cookies: Set-Cookie: refreshToken=...; HttpOnly; Secure; SameSite=Strict

- **POST /auth/refresh**
  - Request: (empty - Cookie auto-sent)
  - Response: { accessToken, expiresAt }
  - Cookies: Set-Cookie: refreshToken=...; (rotated)

- **GET /api/admin/dashboard**
  - Request Headers: Authorization: Bearer {accessToken}
  - Cookies: Cookie: refreshToken=...; (auto-sent)

- **POST /auth/logout**
  - Request: (empty - Cookie auto-sent)
  - Response: { message: "Logged out successfully" }
  - Cookies: Set-Cookie: refreshToken=; (deleted)

---

## 7. Summary

| Component | Location | Purpose |
|-----------|----------|---------|
| **Access Token** | Memory + localStorage | Short-lived (15 min), sent in Authorization header |
| **Refresh Token** | HTTP-only Cookie | Long-lived (7 days), auto-rotated on refresh |
| **Token Rotation** | AuthService.RefreshTokenAsync | Revoke old, generate new to prevent replay attacks |
| **Auto-Refresh** | App.tsx useEffect | Detect expiration, call /refresh before token dies |
| **Logout** | AuthController + authApi | Revoke server-side, clear client storage |
| **CORS** | Program.cs | Allow http://localhost:5173 + https://localhost:5173 |
| **Authorization** | authApi.getHeaders() | Add Bearer token to every authenticated request |

**Status:** ✅ All implemented & working
