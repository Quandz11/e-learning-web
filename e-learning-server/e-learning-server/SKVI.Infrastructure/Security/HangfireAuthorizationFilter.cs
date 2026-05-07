using Hangfire.Dashboard;
using Microsoft.AspNetCore.Http;

namespace SKVI.Infrastructure.Security
{
    public class HangfireAuthorizationFilter : IDashboardAuthorizationFilter
    {
        public bool Authorize(DashboardContext context)
        {
            var httpContext = context.GetHttpContext();
            
            // Cho phép truy cập nếu đã đăng nhập và có role ADMIN
            return httpContext.User.Identity?.IsAuthenticated == true && httpContext.User.IsInRole("ADMIN");
        }
    }
}
