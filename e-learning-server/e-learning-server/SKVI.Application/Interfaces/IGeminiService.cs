using SKVI.Domain.Entities;

namespace SKVI.Application.Interfaces
{
    public interface IGeminiService
    {
        /// <summary>
        /// Sends a prompt to Gemini and gets a string response back for simple chat queries.
        /// </summary>
        Task<string> ChatAsync(string prompt);

        /// <summary>
        /// Generates a list of tasks for the next day based on the user's plan, recent history, and previous day's feedback.
        /// </summary>
        Task<(List<DailyStudyTask> Tasks, string Advice)> GenerateNextTasksAsync(UserStudyPlan plan, string historyContext, string userFeedback);
        
        /// <summary>
        /// Generates an initial study plan based on a user's goal and current knowledge.
        /// </summary>
        Task<List<DailyStudyTask>> GenerateInitialTasksAsync(string goal, string currentKnowledge);
    }
}
