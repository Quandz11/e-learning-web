using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Ai;
using SKVI.Application.Interfaces;
using SKVI.Application.Models;
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
        private readonly IWellnessAccessService _wellnessAccessService;

        public AiChatController(
            IStudyPlanService studyPlanService,
            IAiSettingsService aiSettingsService,
            IWellnessAccessService wellnessAccessService)
        {
            _studyPlanService = studyPlanService;
            _aiSettingsService = aiSettingsService;
            _wellnessAccessService = wellnessAccessService;
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
            var response = new AiCoachStatusDto
            {
                IsEnabled = settings.IsEnabled
            };

            if (!settings.IsEnabled)
            {
                return Ok(response);
            }

            if (!(User?.Identity?.IsAuthenticated ?? false))
            {
                return Ok(response);
            }

            var userId = GetUserId();
            if (userId == Guid.Empty)
            {
                return Ok(response);
            }

            var evaluation = await _wellnessAccessService.EvaluateAccessAsync(userId);
            response.Access = evaluation.Access;
            return Ok(response);
        }

        [HttpGet("plan/dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            try
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
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
            }
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
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
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
            try
            {
                var userId = GetUserId();
                var plan = await _studyPlanService.GetActivePlanAsync(userId);
                return Ok(plan);
            }
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
            }
        }

        [HttpGet("plan/{planId}/today-tasks")]
        public async Task<IActionResult> GetTodayTasks(Guid planId)
        {
            try
            {
                var userId = GetUserId();
                var tasks = await _studyPlanService.GetTodayTasksAsync(userId, planId);
                return Ok(tasks);
            }
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
            }
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
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
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
                var userId = GetUserId();
                var result = await _studyPlanService.SubmitTaskResultAsync(userId, taskId, request);
                return Ok(result);
            }
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
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
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
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
            try
            {
                var userId = GetUserId();
                var history = await _studyPlanService.GetChatHistoryAsync(userId);
                return Ok(history);
            }
            catch (WellnessAccessException ex)
            {
                return PackageForbidden(ex.Code, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
            }
        }

        private IActionResult PackageForbidden(string code, string message)
        {
            return StatusCode(403, new
            {
                code,
                message
            });
        }
    }

    public class ChatRequest
    {
        public string Prompt { get; set; } = string.Empty;
    }
}
