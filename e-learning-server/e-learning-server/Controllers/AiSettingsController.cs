using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.Services;
using SKVI.Domain.Entities;

namespace e_learning_server.Controllers
{
    [ApiController]
    [Route("api/admin/ai-settings")]
    [Authorize(Roles = "ADMIN")]
    public class AiSettingsController : ControllerBase
    {
        private readonly IAiSettingsService _aiSettingsService;

        public AiSettingsController(IAiSettingsService aiSettingsService)
        {
            _aiSettingsService = aiSettingsService;
        }

        [HttpGet]
        public async Task<IActionResult> GetSettings()
        {
            var settings = await _aiSettingsService.GetSettingsAsync();
            return Ok(settings);
        }

        [HttpPut]
        public async Task<IActionResult> UpdateSettings([FromBody] AiSettings newSettings)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var updated = await _aiSettingsService.UpdateSettingsAsync(newSettings);
            return Ok(updated);
        }
    }
}
