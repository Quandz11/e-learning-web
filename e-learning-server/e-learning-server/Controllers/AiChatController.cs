using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.Services;

namespace e_learning_server.Controllers
{
    [ApiController]
    [Route("api/ai")]
    [Authorize]
    public class AiChatController : ControllerBase
    {
        private readonly IStudyPlanService _studyPlanService;
        private readonly IAiSettingsService _aiSettingsService;

        public AiChatController(IStudyPlanService studyPlanService, IAiSettingsService aiSettingsService)
        {
            _studyPlanService = studyPlanService;
            _aiSettingsService = aiSettingsService;
        }

        private Guid GetUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdStr ?? Guid.Empty.ToString());
        }

        [HttpGet("settings/status")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAiStatus()
        {
            var settings = await _aiSettingsService.GetSettingsAsync();
            return Ok(new { isEnabled = settings.IsEnabled });
        }

        [HttpPost("plan/init")]
        public async Task<IActionResult> InitializePlan([FromBody] InitPlanRequest request)
        {
            var userId = GetUserId();
            try
            {
                var plan = await _studyPlanService.InitializePlanAsync(userId, request.Goal, request.CurrentKnowledge);
                return Ok(plan);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message }); // AI not configured
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi từ AI: " + ex.Message });
            }
        }

        [HttpGet("plan/active")]
        public async Task<IActionResult> GetActivePlan()
        {
            var userId = GetUserId();
            var plan = await _studyPlanService.GetActivePlanAsync(userId);
            if (plan == null) return NotFound("No active plan");
            return Ok(plan);
        }

        [HttpGet("plan/{planId}/today-tasks")]
        public async Task<IActionResult> GetTodayTasks(Guid planId)
        {
            var tasks = await _studyPlanService.GetTodayTasksAsync(planId);
            return Ok(tasks);
        }

        [HttpPost("tasks/{taskId}/submit")]
        public async Task<IActionResult> SubmitTask(Guid taskId, [FromBody] SubmitTaskRequest request)
        {
            try
            {
                var result = await _studyPlanService.SubmitTaskResultAsync(taskId, request.Feedback);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] ChatRequest request)
        {
            var userId = GetUserId();
            try
            {
                var response = await _studyPlanService.ChatDirectlyAsync(userId, request.Prompt);
                return Ok(new { response });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi từ AI: " + ex.Message });
            }
        }

        [HttpGet("chat/history")]
        public async Task<IActionResult> GetChatHistory()
        {
            var userId = GetUserId();
            var history = await _studyPlanService.GetChatHistoryAsync(userId);
            return Ok(history);
        }
    }

    public class InitPlanRequest
    {
        public string Goal { get; set; }
        public string CurrentKnowledge { get; set; }
    }

    public class SubmitTaskRequest
    {
        public string Feedback { get; set; }
    }

    public class ChatRequest
    {
        public string Prompt { get; set; }
    }
}
