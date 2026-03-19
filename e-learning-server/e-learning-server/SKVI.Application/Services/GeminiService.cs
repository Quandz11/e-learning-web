using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services
{
    public class GeminiService : IGeminiService
    {
        private readonly HttpClient _httpClient;
        private readonly ApplicationDbContext _dbContext;

        public GeminiService(HttpClient httpClient, ApplicationDbContext dbContext)
        {
            _httpClient = httpClient;
            _dbContext = dbContext;
        }

        private async Task<AiSettings> GetSettingsAsync()
        {
            var settings = await _dbContext.AiSettings.FirstOrDefaultAsync();
            if (settings == null || !settings.IsEnabled || string.IsNullOrEmpty(settings.ApiKey))
            {
                throw new InvalidOperationException("AI features are not configured or are disabled.");
            }
            return settings;
        }

        private async Task<string> CallGeminiApiAsync(string prompt, string? systemInstruction = null)
        {
            var settings = await GetSettingsAsync();
            var model = GeminiModelCatalog.Normalize(settings.ModelName);
            var apiKey = settings.ApiKey;
            var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

            var body = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[] { new { text = prompt } }
                    }
                },
                systemInstruction = systemInstruction != null ? new
                {
                    parts = new[] { new { text = systemInstruction } }
                } : null
            };

            var jsonContent = new StringContent(JsonSerializer.Serialize(body, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase, DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull }), Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(url, jsonContent);
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"Gemini API Error: {response.StatusCode} - {error}");
            }

            var responseStr = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseStr);

            if (!doc.RootElement.TryGetProperty("candidates", out var candidates) || candidates.GetArrayLength() == 0)
            {
                throw new Exception("Gemini API returned no candidates.");
            }

            var textResult = candidates[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString();

            return textResult ?? string.Empty;
        }

        public async Task<string> ChatAsync(string prompt)
        {
            var settings = await GetSettingsAsync();
            return await CallGeminiApiAsync(prompt, settings.SystemPrompt);
        }

        public async Task<List<DailyStudyTask>> GenerateInitialTasksAsync(string goal, string currentKnowledge)
        {
            var settings = await GetSettingsAsync();
            
            var prompt = $@"
Dựa vào thông tin sau của học viên:
Mục tiêu học tập: {goal}
Trình độ hiện tại: {currentKnowledge}

Hãy tạo ra một danh sách công việc học tập (tasks = nhiệm vụ) cho 3 ngày đầu tiên.
Yêu cầu định dạng JSON strict như sau, không có markdown hay bất kì text nào khác bên ngoài mảng JSON:
[
  {{ ""dayOffset"": 0, ""content"": ""Nhiệm vụ cụ thể ngày 1"" }},
  {{ ""dayOffset"": 1, ""content"": ""Nhiệm vụ cụ thể ngày 2"" }},
  {{ ""dayOffset"": 2, ""content"": ""Nhiệm vụ cụ thể ngày 3"" }}
]";

            var systemInstruction = "Bạn là hệ thống tạo lộ trình học tập trả về đúng định dạng mảng JSON chứa các Object. Không bao giờ serialize text thừa.";
            var jsonRes = await CallGeminiApiAsync(prompt, systemInstruction);

            // Clean json mapping (remove ```json wrappers if Gemini still outputs them)
            jsonRes = jsonRes.Replace("```json", "").Replace("```", "").Trim();

            var taskDtos = JsonSerializer.Deserialize<List<GeminiTaskResponseDto>>(jsonRes, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            var tasks = new List<DailyStudyTask>();
            
            if (taskDtos != null)
            {
                foreach (var dto in taskDtos)
                {
                    tasks.Add(new DailyStudyTask
                    {
                        TaskDate = DateTime.UtcNow.AddDays(dto.DayOffset).Date,
                        Content = dto.Content,
                        IsCompleted = false
                    });
                }
            }

            return tasks;
        }

        public async Task<(List<DailyStudyTask> Tasks, string Advice)> GenerateNextTasksAsync(UserStudyPlan plan, string historyContext, string userFeedback)
        {
            var prompt = $@"
Học viên đang học với mục tiêu: {plan.Goal}
Trình độ nền: {plan.CurrentKnowledgeLevel}
Lịch sử học gần đây: {historyContext}
Phản hồi của học viên về bài tập vừa hoàn thành: '{userFeedback}'

Nhiệm vụ của bạn:
1. Đưa ra 1 đoạn nhận xét/lời khuyên (Advice) ngắn gọn để động viên và giải đáp vướng mắc của học viên.
2. Tạo ra 2 nhiệm vụ học tập (Tasks) cho 2 ngày tiếp theo dựa trên tiến độ và phản hồi đó.

Bắt buộc trả về đúng định dạng JSON strict sau, không markdown, không dư thừa text:
{{
  ""advice"": ""Lời khuyên ngắn gọn của bạn..."",
  ""nextTasks"": [
     {{ ""dayOffset"": 1, ""content"": ""Nhiệm vụ ngày tiếp theo"" }},
     {{ ""dayOffset"": 2, ""content"": ""Nhiệm vụ ngày sau đó"" }}
  ]
}}";
            var jsonRes = await CallGeminiApiAsync(prompt, "Bạn là hệ thống tạo lộ trình trả về JSON strict format theo pattern yêu cầu.");
            jsonRes = jsonRes.Replace("```json", "").Replace("```", "").Trim();

            var resDto = JsonSerializer.Deserialize<GeminiNextTaskResponseDto>(jsonRes, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            
            var tasks = new List<DailyStudyTask>();
            if (resDto?.NextTasks != null)
            {
                foreach (var dto in resDto.NextTasks)
                {
                    tasks.Add(new DailyStudyTask
                    {
                        TaskDate = DateTime.UtcNow.AddDays(dto.DayOffset).Date,
                        Content = dto.Content,
                        IsCompleted = false
                    });
                }
            }
            
            return (tasks, resDto?.Advice ?? "Tuyệt vời! Hãy tiếp tục phát huy nhé.");
        }
        
        // Internal DTOs for json deserialization mapping
        private class GeminiTaskResponseDto 
        { 
            public int DayOffset { get; set; } 
            public string Content { get; set; } 
        }

        private class GeminiNextTaskResponseDto
        {
            public string Advice { get; set; }
            public List<GeminiTaskResponseDto> NextTasks { get; set; }
        }
    }
}
