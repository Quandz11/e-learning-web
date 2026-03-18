using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Documents;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class DocumentService : IDocumentService
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IBunnyStreamService _bunnyStreamService;
    private readonly IHttpClientFactory _httpClientFactory;
    private const long MaxFileSizeBytes = 50 * 1024 * 1024; // 50MB

    public DocumentService(
        ApplicationDbContext dbContext,
        IBunnyStreamService bunnyStreamService,
        IHttpClientFactory httpClientFactory)
    {
        _dbContext = dbContext;
        _bunnyStreamService = bunnyStreamService;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<DocumentUploadResponse> UploadPdfAsync(IFormFile file, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            throw new ArgumentException("File is empty", nameof(file));
        }

        // Validate file size
        if (file.Length > MaxFileSizeBytes)
        {
            throw new ArgumentException($"File size exceeds maximum allowed size of {MaxFileSizeBytes / (1024 * 1024)}MB", nameof(file));
        }

        // Validate file extension
        var extension = Path.GetExtension(file.FileName)?.ToLowerInvariant();
        if (extension != ".pdf")
        {
            throw new ArgumentException("Only PDF files are allowed", nameof(file));
        }

        // Validate MIME type
        if (file.ContentType != "application/pdf")
        {
            throw new ArgumentException("Invalid file type. Only PDF files are allowed", nameof(file));
        }

        // Upload to Bunny storage
        await using var stream = file.OpenReadStream();
        var cdnUrl = await _bunnyStreamService.UploadDocumentAsync(stream, file.FileName, cancellationToken);

        // Store full CDN URL for direct access
        var document = new Document
        {
            Id = Guid.NewGuid(),
            FileName = file.FileName,
            BunnyStoragePath = cdnUrl, // Store full CDN URL
            FileSizeBytes = file.Length,
            UploadedAt = DateTime.UtcNow
        };

        _dbContext.Documents.Add(document);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new DocumentUploadResponse
        {
            DocumentId = document.Id,
            FileUrl = cdnUrl
        };
    }

    public async Task<DocumentResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var document = await _dbContext.Documents.FirstOrDefaultAsync(d => d.Id == id, cancellationToken);
        
        if (document == null)
        {
            return null;
        }

        return new DocumentResponse
        {
            Id = document.Id,
            FileName = document.FileName,
            FileUrl = document.BunnyStoragePath, // Already full CDN URL
            FileSizeBytes = document.FileSizeBytes,
            UploadedAt = document.UploadedAt
        };
    }

    public async Task<DocumentStreamResponse?> GetPdfStreamByUrlAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(fileUrl))
        {
            return null;
        }

        var normalizedUrl = fileUrl.Trim();

        if (!Uri.TryCreate(normalizedUrl, UriKind.Absolute, out var uri) ||
            (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
        {
            return null;
        }

        // Only allow proxying URLs that exist in our document table.
        var document = await _dbContext.Documents
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.BunnyStoragePath == normalizedUrl, cancellationToken);

        if (document == null)
        {
            return null;
        }

        var httpClient = _httpClientFactory.CreateClient();
        using var response = await httpClient.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException("Failed to fetch PDF from storage.");
        }

        var bytes = await response.Content.ReadAsByteArrayAsync(cancellationToken);
        var upstreamContentType = response.Content.Headers.ContentType?.MediaType;
        var contentType = string.Equals(upstreamContentType, "application/pdf", StringComparison.OrdinalIgnoreCase)
            ? "application/pdf"
            : "application/pdf";

        return new DocumentStreamResponse
        {
            Content = bytes,
            ContentType = contentType,
            FileName = document.FileName
        };
    }

    private string ExtractPathFromCdnUrl(string cdnUrl)
    {
        // Extract path after CDN base URL
        // Example: "https://e-learning-skvi.b-cdn.net/documents/abc123.pdf" -> "documents/abc123.pdf"
        var uri = new Uri(cdnUrl);
        return uri.AbsolutePath.TrimStart('/');
    }

    private string ReconstructCdnUrl(string storagePath)
    {
        // This is a simple reconstruction - in production you might want to inject BunnySettings
        // For now, we'll rely on the path being stored correctly
        // You could also store the full URL in the database if preferred
        return storagePath; // Placeholder - will be improved if needed
    }
}
