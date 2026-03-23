namespace SKVI.Infrastructure.Services;

public class ZaloOtpSettings
{
    public bool Enabled { get; set; } = false;
    public string ApiBaseUrl { get; set; } = "https://business.openapi.zalo.me";
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public string TokenApiBaseUrl { get; set; } = "https://oauth.zaloapp.com";
    public string RefreshPath { get; set; } = "/v4/oa/access_token";
    public string AppId { get; set; } = string.Empty;
    public string AppSecret { get; set; } = string.Empty;
    public int AccessTokenExpiresInSeconds { get; set; } = 0;
    public int RefreshBufferSeconds { get; set; } = 120;
    public string TemplateId { get; set; } = string.Empty;
    public bool UseHashPhone { get; set; } = false;
    public string Mode { get; set; } = string.Empty;
    public string SendingMode { get; set; } = string.Empty;
    public int ExpireMinutes { get; set; } = 10;
    public string OtpFieldName { get; set; } = "otp";
    public string PurposeFieldName { get; set; } = "purpose";
    public string ExpireMinutesFieldName { get; set; } = "expired_minutes";
    public string TrackingPrefix { get; set; } = "otp";
}
