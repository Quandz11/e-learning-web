using Microsoft.AspNetCore.Http;
using SKVI.Application.DTOs.Documents;

namespace SKVI.Application.Interfaces;

public interface IDocumentService
{
    Task<DocumentUploadResponse> UploadPdfAsync(IFormFile file, CancellationToken cancellationToken = default);
    Task<DocumentResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
