using SKVI.Application.DTOs.Dashboard;

namespace SKVI.Application.Interfaces;

public interface ICareDashboardService
{
    Task<CareDashboardStatsDto> GetStatsAsync(CancellationToken cancellationToken = default);
    Task<List<SupportTicketDto>> GetSupportTicketsAsync(int page = 1, int pageSize = 20, string? status = null, string? search = null, CancellationToken cancellationToken = default);
    Task<SupportTicketDto> GetSupportTicketAsync(string ticketId, CancellationToken cancellationToken = default);
    Task<string> CreateSupportTicketAsync(CreateSupportTicketDto request, CancellationToken cancellationToken = default);
    Task UpdateSupportTicketAsync(string ticketId, UpdateSupportTicketDto request, CancellationToken cancellationToken = default);
    Task<List<CareCustomerDto>> GetCustomersAsync(int page = 1, int pageSize = 20, string? search = null, CancellationToken cancellationToken = default);
    Task<List<SatisfactionFeedbackDto>> GetSatisfactionTrendAsync(int days = 30, CancellationToken cancellationToken = default);
    Task<List<CareChatMessageDto>> GetInboxMessagesAsync(CancellationToken cancellationToken = default);
}

public interface IAgentDashboardService
{
    Task<AgentDashboardStatsDto> GetStatsAsync(Guid agentId, CancellationToken cancellationToken = default);
    Task<List<SalesDataDto>> GetSalesChartAsync(Guid agentId, int month = 0, CancellationToken cancellationToken = default);
    Task<List<ReferralDto>> GetReferralsAsync(Guid agentId, int page = 1, int pageSize = 20, string? status = null, CancellationToken cancellationToken = default);
    Task<CommissionBreakdownDto> GetCommissionAsync(Guid agentId, CancellationToken cancellationToken = default);
    Task<List<AgentStudentDto>> GetStudentsAsync(Guid agentId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default);
    Task<List<LeaderboardEntryDto>> GetLeaderboardAsync(CancellationToken cancellationToken = default);
    Task<ReferralLinkResponseDto> GenerateReferralLinkAsync(Guid agentId, GenerateReferralLinkRequestDto request, CancellationToken cancellationToken = default);
    Task<AgentReportDto> GetReportAsync(Guid agentId, int year, int month, CancellationToken cancellationToken = default);
}

public interface ILecturerDashboardService
{
    Task<LecturerDashboardStatsDto> GetStatsAsync(Guid lecturerId, CancellationToken cancellationToken = default);
    Task<List<LecturerCourseDto>> GetCoursesAsync(Guid lecturerId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default);
    Task<List<LecturerLessonDto>> GetLessonsAsync(Guid lecturerId, CancellationToken cancellationToken = default);
    Task<List<PendingQuizDto>> GetPendingQuizzesAsync(Guid lecturerId, CancellationToken cancellationToken = default);
    Task<List<QuizSubmissionDto>> GetQuizSubmissionsAsync(Guid quizId, string? status = null, CancellationToken cancellationToken = default);
    Task<List<StudentProgressDto>> GetStudentProgressAsync(Guid lecturerId, CancellationToken cancellationToken = default);
    Task<StudentProgressDto?> GetStudentProgressDetailAsync(Guid lecturerId, Guid studentId, CancellationToken cancellationToken = default);
    Task<LecturerAnalyticsDto> GetAnalyticsAsync(Guid lecturerId, CancellationToken cancellationToken = default);
    Task<List<LecturerMessageDto>> GetMessagesAsync(Guid lecturerId, CancellationToken cancellationToken = default);
    Task GradeQuizSubmissionAsync(string submissionId, GradeQuizSubmissionDto request, CancellationToken cancellationToken = default);
    Task<List<ZoomClassDto>> GetZoomScheduleAsync(Guid lecturerId, CancellationToken cancellationToken = default);
}
