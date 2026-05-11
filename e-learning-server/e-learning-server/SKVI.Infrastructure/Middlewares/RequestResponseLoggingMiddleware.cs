using System.Diagnostics;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace SKVI.Infrastructure.Middlewares
{
    public class RequestResponseLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<RequestResponseLoggingMiddleware> _logger;

        public RequestResponseLoggingMiddleware(RequestDelegate next, ILogger<RequestResponseLoggingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            var stopwatch = Stopwatch.StartNew();
            var request = context.Request;

            // Log Request
            var requestBody = await ReadRequestBody(request);
            _logger.LogInformation("HTTP Request: {Method} {Path}{QueryString} Body: {Body}", 
                request.Method, request.Path, request.QueryString, requestBody);

            // Copy original response body stream
            var originalBodyStream = context.Response.Body;

            using var responseBody = new MemoryStream();
            context.Response.Body = responseBody;

            try
            {
                await _next(context);
            }
            finally
            {
                stopwatch.Stop();

                // Log Response
                var response = context.Response;
                var responseBodyText = await ReadResponseBody(response);
                
                _logger.LogInformation("HTTP Response: {StatusCode} Duration: {Duration}ms Body: {Body}", 
                    response.StatusCode, stopwatch.ElapsedMilliseconds, responseBodyText);

                // Copy back to original stream
                await responseBody.CopyToAsync(originalBodyStream);
            }
        }

        private async Task<string> ReadRequestBody(HttpRequest request)
        {
            request.EnableBuffering();

            using var reader = new StreamReader(request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true);
            var body = await reader.ReadToEndAsync();
            request.Body.Position = 0;

            return body.Length > 1000 ? body.Substring(0, 1000) + "..." : body;
        }

        private async Task<string> ReadResponseBody(HttpResponse response)
        {
            response.Body.Seek(0, SeekOrigin.Begin);
            var body = await new StreamReader(response.Body).ReadToEndAsync();
            response.Body.Seek(0, SeekOrigin.Begin);

            return body.Length > 1000 ? body.Substring(0, 1000) + "..." : body;
        }
    }
}
