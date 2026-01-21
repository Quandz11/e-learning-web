namespace SKVI.Application.DTOs.Auth;

public class VerifyTwoFactorRequest
{
    public string Code { get; set; } = string.Empty;
}

public class EnableTwoFactorRequest
{
    public string Secret { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? Password { get; set; } 
}

public class DisableTwoFactorRequest
{
    public string Password { get; set; } = string.Empty;
}
