using Microsoft.EntityFrameworkCore;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services
{
    public interface IStudyPlanService
    {
        Task<UserStudyPlan> InitializePlanAsync(Guid userId, string goal, string currentKnowledge);
        Task<UserStudyPlan> GetActivePlanAsync(Guid userId);
        Task<List<DailyStudyTask>> GetTodayTasksAsync(Guid planId);
        Task<DailyStudyTask> SubmitTaskResultAsync(Guid taskId, string feedback);
        Task<string> ChatDirectlyAsync(Guid userId, string prompt);
        Task<List<AiChatMessage>> GetChatHistoryAsync(Guid userId);
    }

    public class StudyPlanService : IStudyPlanService
    {
        private readonly ApplicationDbContext _dbContext;
        private readonly IGeminiService _geminiService;

        public StudyPlanService(ApplicationDbContext dbContext, IGeminiService geminiService)
        {
            _dbContext = dbContext;
            _geminiService = geminiService;
        }

        public async Task<UserStudyPlan> InitializePlanAsync(Guid userId, string goal, string currentKnowledge)
        {
            // Close any existing plans
            var existingPans = await _dbContext.UserStudyPlans.Where(p => p.UserId == userId && p.Status == "Active").ToListAsync();
            foreach(var plan in existingPans)
            {
                plan.Status = "Completed";
            }

            var newPlan = new UserStudyPlan
            {
                UserId = userId,
                Goal = goal,
                CurrentKnowledgeLevel = currentKnowledge,
                Status = "Active"
            };
            
            _dbContext.UserStudyPlans.Add(newPlan);
            
            // Trigger AI to generate first 3 days of tasks
            var initialTasks = await _geminiService.GenerateInitialTasksAsync(goal, currentKnowledge);
            foreach(var task in initialTasks)
            {
                task.PlanId = newPlan.Id;
                _dbContext.DailyStudyTasks.Add(task);
            }

            // Also send a welcome message to chat
            _dbContext.AiChatMessages.Add(new AiChatMessage
            {
                UserId = userId,
                Role = "model",
                Content = $"Chào bạn! Mình đã nhận được mục tiêu '{goal}' của bạn. Mình đã tạo lộ trình những ngày đầu tiên cho bạn rồi đó. Bạn xem trong phần Nhiệm vụ nhé!"
            });

            await _dbContext.SaveChangesAsync();
            return newPlan;
        }

        public async Task<UserStudyPlan> GetActivePlanAsync(Guid userId)
        {
            return await _dbContext.UserStudyPlans
                .Include(p => p.DailyTasks)
                .FirstOrDefaultAsync(p => p.UserId == userId && p.Status == "Active");
        }

        public async Task<List<DailyStudyTask>> GetTodayTasksAsync(Guid planId)
        {
            var today = DateTime.UtcNow.Date;
            return await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == planId && t.TaskDate.Date <= today && !t.IsCompleted)
                .OrderBy(t => t.TaskDate)
                .ToListAsync();
        }

        public async Task<DailyStudyTask> SubmitTaskResultAsync(Guid taskId, string feedback)
        {
            var task = await _dbContext.DailyStudyTasks.Include(t => t.Plan).FirstOrDefaultAsync(t => t.Id == taskId);
            if (task == null) throw new Exception("Task not found");

            task.IsCompleted = true;
            task.UserFeedback = feedback;

            // Trigger AI to evaluate and generate next tasks based on this completion
            // We provide a brief history context to the AI
            var recentTasks = await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == task.PlanId)
                .OrderByDescending(t => t.TaskDate)
                .Take(5)
                .Select(t => $"- Date: {t.TaskDate:yyyy-MM-dd}, Task: {t.Content}, Completed: {t.IsCompleted}, Feedback: {t.UserFeedback}")
                .ToListAsync();

            var historyContext = string.Join("\n", recentTasks);

            var (newTasks, advice) = await _geminiService.GenerateNextTasksAsync(task.Plan, historyContext, feedback);
            task.AiAdvice = advice;

            _dbContext.DailyStudyTasks.Update(task);

            // Save the newly generated tasks
            foreach(var newTask in newTasks)
            {
                newTask.PlanId = task.PlanId;
                _dbContext.DailyStudyTasks.Add(newTask);
            }

            await _dbContext.SaveChangesAsync();
            return task;
        }

        public async Task<string> ChatDirectlyAsync(Guid userId, string prompt)
        {
            // Log user message
            _dbContext.AiChatMessages.Add(new AiChatMessage
            {
                UserId = userId,
                Role = "user",
                Content = prompt
            });
            await _dbContext.SaveChangesAsync();

            // Call AI
            var response = await _geminiService.ChatAsync(prompt);

            // Log AI response
            _dbContext.AiChatMessages.Add(new AiChatMessage
            {
                UserId = userId,
                Role = "model",
                Content = response
            });
            await _dbContext.SaveChangesAsync();

            return response;
        }

        public async Task<List<AiChatMessage>> GetChatHistoryAsync(Guid userId)
        {
            return await _dbContext.AiChatMessages
                .Where(m => m.UserId == userId)
                .OrderBy(m => m.CreatedAt)
                .ToListAsync();
        }
    }
}
