using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Documents;
using SKVI.Application.Interfaces;

namespace SKVI.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class DocumentsController : ControllerBase
{
    private readonly IDocumentService _documentService;

    public DocumentsController(IDocumentService documentService)
    {
        _documentService = documentService;
    }

    [HttpPost("upload")]
    [DisableRequestSizeLimit]
    [RequestFormLimits(MultipartBodyLengthLimit = 52428800)] // 50MB
    public async Task<ActionResult<DocumentUploadResponse>> Upload(IFormFile file, CancellationToken cancellationToken)
    {
        try
        {
            var result = await _documentService.UploadPdfAsync(file, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Upload failed: {ex.Message}" });
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DocumentResponse>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var document = await _documentService.GetByIdAsync(id, cancellationToken);
        
        if (document == null)
        {
            return NotFound(new { message = "Document not found" });
        }

        return Ok(document);
    }

    [AllowAnonymous]
    [HttpGet("proxy")]
    public async Task<IActionResult> ProxyPdf([FromQuery] string url, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            return BadRequest(new { message = "Document URL is required." });
        }

        try
        {
            var document = await _documentService.GetPdfStreamByUrlAsync(url, cancellationToken);
            if (document == null)
            {
                return NotFound(new { message = "Document not found." });
            }

            Response.Headers.CacheControl = "private, max-age=300";
            return File(document.Content, document.ContentType, enableRangeProcessing: true);
        }
        catch (Exception ex)
        {
            return StatusCode(502, new { message = $"Failed to stream PDF: {ex.Message}" });
        }
    }
}
