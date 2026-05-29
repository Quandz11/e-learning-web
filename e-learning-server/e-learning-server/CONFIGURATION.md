# Configuration

The server supports two secure configuration styles:

1. ASP.NET Core native keys (recommended):
- `ConnectionStrings__DefaultConnection`
- `JwtSettings__Secret`
- `PayOSSettings__ApiKey`
- ...

2. Flat alias keys (for convenience), for example:
- `DB_CONNECTION_STRING`
- `JWT_SECRET`
- `PAYOS_API_KEY`

At startup, `Program.cs` maps flat alias keys into ASP.NET Core config keys.

## Local setup

1. Copy `.env.example` and fill values in your own secret store or machine environment.
2. Do not commit real secrets into `appsettings*.json`.
3. Keep `appsettings*.json` with placeholders only.

## Required values to start

- `ConnectionStrings:DefaultConnection`
- `JwtSettings:Secret`

If either value is missing, startup will fail early with a clear error.
