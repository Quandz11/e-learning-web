using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Ai;
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

        [HttpGet("plan/dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            var userId = GetUserId();
            var dashboard = await _studyPlanService.GetDashboardAsync(userId);
            return Ok(dashboard ?? new StudyPlanDashboardDto
            {
                Plan = null,
                TodayTasks = [],
                LatestCheckIn = null,
                OpenSupportAlerts = 0,
                GuidanceMessage = string.Empty
            });
        }

        [HttpPost("plan/init")]
        public async Task<IActionResult> InitializePlan([FromBody] InitializeStudyPlanRequest request)
        {
            var userId = GetUserId();

            try
            {
                var plan = await _studyPlanService.InitializePlanAsync(userId, request);
                return Ok(plan);
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

        [HttpGet("plan/active")]
        public async Task<IActionResult> GetActivePlan()
        {
            var userId = GetUserId();
            var plan = await _studyPlanService.GetActivePlanAsync(userId);
            return Ok(plan);
        }

        [HttpGet("plan/{planId}/today-tasks")]
        public async Task<IActionResult> GetTodayTasks(Guid planId)
        {
            var tasks = await _studyPlanService.GetTodayTasksAsync(planId);
            return Ok(tasks);
        }

        [HttpPost("check-in")]
        public async Task<IActionResult> SubmitCheckIn([FromBody] DailyStudyCheckInRequest request)
        {
            var userId = GetUserId();

            try
            {
                var checkIn = await _studyPlanService.SubmitDailyCheckInAsync(userId, request);
                return Ok(checkIn);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Không thể lưu check-in: " + ex.Message });
            }
        }

        [HttpPost("tasks/{taskId}/submit")]
        public async Task<IActionResult> SubmitTask(Guid taskId, [FromBody] SubmitStudyTaskResultRequest request)
        {
            try
            {
                var result = await _studyPlanService.SubmitTaskResultAsync(taskId, request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Không thể cập nhật task: " + ex.Message });
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

    public class ChatRequest
    {
        public string Prompt { get; set; } = string.Empty;
    }
}
