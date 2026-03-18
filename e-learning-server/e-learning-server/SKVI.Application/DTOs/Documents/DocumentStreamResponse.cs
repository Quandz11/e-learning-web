namespace SKVI.Application.DTOs.Documents;

public class DocumentStreamResponse
{
    public byte[] Content { get; set; } = Array.Empty<byte>();
    public string ContentType { get; set; } = "application/pdf";
    public string FileName { get; set; } = string.Empty;
}
