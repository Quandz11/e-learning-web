namespace SKVI.Application.Models;

public class WellnessAccessException : UnauthorizedAccessException
{
    public string Code { get; }

    public WellnessAccessException(string code, string message)
        : base(message)
    {
        Code = code;
    }
}
