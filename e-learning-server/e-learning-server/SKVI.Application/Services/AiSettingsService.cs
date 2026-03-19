using Microsoft.EntityFrameworkCore;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services
{
    public interface IAiSettingsService
    {
        Task<AiSettings> GetSettingsAsync();
        Task<AiSettings> UpdateSettingsAsync(AiSettings settings);
    }

    public class AiSettingsService : IAiSettingsService
    {
        private readonly ApplicationDbContext _dbContext;

        public AiSettingsService(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<AiSettings> GetSettingsAsync()
        {
            var settings = await _dbContext.AiSettings.FirstOrDefaultAsync();
            if (settings == null)
            {
                // Return default unconfigured state instead of purely null
                settings = new AiSettings
                {
                    ApiKey = "",
                    ModelName = GeminiModelCatalog.DefaultModel,
                    SystemPrompt = "Bạn là trợ lý AI chuyên gia hỗ trợ học tập.",
                    IsEnabled = false
                };
                _dbContext.AiSettings.Add(settings);
                await _dbContext.SaveChangesAsync();
            }
            var normalizedModel = GeminiModelCatalog.Normalize(settings.ModelName);
            if (!string.Equals(settings.ModelName, normalizedModel, StringComparison.OrdinalIgnoreCase))
            {
                settings.ModelName = normalizedModel;
                settings.UpdatedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync();
            }

            return settings;
        }

        public async Task<AiSettings> UpdateSettingsAsync(AiSettings newSettings)
        {
            newSettings.ModelName = GeminiModelCatalog.Normalize(newSettings.ModelName);

            var existing = await _dbContext.AiSettings.FirstOrDefaultAsync();
            if (existing == null)
            {
                _dbContext.AiSettings.Add(newSettings);
            }
            else
            {
                existing.ApiKey = newSettings.ApiKey;
                existing.ModelName = newSettings.ModelName;
                existing.SystemPrompt = newSettings.SystemPrompt;
                existing.IsEnabled = newSettings.IsEnabled;
                existing.UpdatedAt = DateTime.UtcNow;
                _dbContext.AiSettings.Update(existing);
            }

            await _dbContext.SaveChangesAsync();
            return existing ?? newSettings;
        }
    }
}
