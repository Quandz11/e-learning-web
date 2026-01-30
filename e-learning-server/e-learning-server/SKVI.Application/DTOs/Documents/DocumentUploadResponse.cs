namespace SKVI.Application.DTOs.Documents;

public class DocumentUploadResponse
{
    public Guid DocumentId { get; set; }
    public string FileUrl { get; set; } = string.Empty;
}
