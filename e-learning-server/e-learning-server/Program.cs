using System.Text;
using e_learning_server.Controllers;
using Hangfire;
using Hangfire.SqlServer;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SKVI.Application.Interfaces;
using SKVI.Application.Services;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security;
using SKVI.Infrastructure.Services;
using SKVI.Infrastructure.VideoStreaming;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// Database Context
builder.Services.AddDbContextPool<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Configuration
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));
builder.Services.Configure<SmtpSettings>(builder.Configuration.GetSection("SmtpSettings"));
builder.Services.Configure<BunnySettings>(builder.Configuration.GetSection("BunnySettings"));
builder.Services.Configure<PayOSSettings>(builder.Configuration.GetSection("PayOSSettings"));
builder.Services.Configure<ZaloOtpSettings>(builder.Configuration.GetSection("ZaloOtpSettings"));
builder.Services.Configure<WellnessSecuritySettings>(builder.Configuration.GetSection("WellnessSecuritySettings"));

// Services
builder.Services.AddMemoryCache();
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPhoneAuthService, PhoneAuthService>();
builder.Services.AddScoped<IWellnessService, WellnessService>();
builder.Services.AddScoped<IWellnessAccessService, WellnessAccessService>();
builder.Services.AddScoped<IWellnessSettingsService, WellnessSettingsService>();
builder.Services.AddSingleton<IWellnessRateLimiter, WellnessRateLimiter>();
builder.Services.AddScoped<IWellnessEncryptionService, WellnessEncryptionService>();
builder.Services.AddScoped<IUserReferralService, UserReferralService>();
builder.Services.AddScoped<IVideoService, VideoService>();
builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<ICourseService, CourseService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ILessonService, LessonService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IInstructorService, InstructorService>();
builder.Services.AddScoped<IEnrollmentService, EnrollmentService>();
builder.Services.AddScoped<ICheckoutService, CheckoutService>();
builder.Services.AddScoped<ILessonProgressService, LessonProgressService>();
builder.Services.AddScoped<ILessonProgressService, LessonProgressService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<ICareDashboardService, CareDashboardService>();
builder.Services.AddScoped<IAgentDashboardService, AgentDashboardService>();
builder.Services.AddScoped<ILecturerDashboardService, LecturerDashboardService>();
builder.Services.AddScoped<IArticleService, ArticleService>();
builder.Services.AddScoped<IMenuService, MenuService>();
builder.Services.AddScoped<IQuizService, QuizService>();
builder.Services.AddScoped<IQuizSubmissionService, QuizSubmissionService>();
builder.Services.AddScoped<ITestimonialService, TestimonialService>();
builder.Services.AddScoped<IHomeVideoSectionService, HomeVideoSectionService>();
builder.Services.AddScoped<IWhyChooseUsService, WhyChooseUsService>();
builder.Services.AddScoped<ForumService>();

// AI Services
builder.Services.AddScoped<IAiSettingsService, AiSettingsService>();
builder.Services.AddScoped<IGeminiService, GeminiService>();
builder.Services.AddScoped<IStudyPlanService, StudyPlanService>();

// Guest Conversation Service (Singleton for in-memory storage)
builder.Services.AddSingleton<IGuestConversationService, GuestConversationService>();

// Background Services
builder.Services.AddHostedService<SKVI.Infrastructure.BackgroundServices.GuestConversationCleanupService>();

// Ngăn background service crash (VD: HangfireServer) kéo chết toàn bộ app
// Đặc biệt quan trọng khi Hangfire DB schema chưa được tạo trên Azure SQL
builder.Services.Configure<HostOptions>(options =>
{
    options.BackgroundServiceExceptionBehavior = BackgroundServiceExceptionBehavior.Ignore;
});

// Hangfire Configuration — dùng schema 'dbo' để tránh lỗi CREATE SCHEMA trên Azure SQL
// Azure SQL user có quyền CREATE TABLE trong dbo nhưng không có quyền CREATE SCHEMA mới
builder.Services.AddHangfire(configuration => configuration
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection"), new SqlServerStorageOptions
    {
        SchemaName = "dbo",                    // Dùng schema dbo có sẵn, không cần tạo schema HangFire mới
        CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
        SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
        QueuePollInterval = TimeSpan.Zero,
        UseRecommendedIsolationLevel = true,
        PrepareSchemaIfNecessary = true        // Tự tạo các bảng Hangfire nếu chưa có
    }));

// Add the processing server as IHostedService
builder.Services.AddHangfireServer();

// Application Insights — chỉ bật khi có connection string (tránh crash trên môi trường không cấu hình)
// APPLICATIONINSIGHTS_CONNECTION_STRING phải được set trong Azure App Settings
var appInsightsConnStr = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]
    ?? builder.Configuration["ApplicationInsights:ConnectionString"];
if (!string.IsNullOrEmpty(appInsightsConnStr))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnStr;
    });
}

// Video Security Service (for signed URLs)
builder.Services.AddScoped<IVideoSecurityService>(sp =>
{
    var bunnySettings = sp.GetRequiredService<IOptions<BunnySettings>>().Value;
    return new VideoSecurityService(bunnySettings);
});

builder.Services.AddHttpClient<IBunnyStreamService, BunnyStreamService>();
builder.Services.AddHttpClient<IPayOSService, PayOSService>((sp, client) =>
{
    var settings = sp.GetRequiredService<IOptions<PayOSSettings>>().Value;
    client.BaseAddress = new Uri(settings.ApiBaseUrl.TrimEnd('/'));
    client.Timeout = TimeSpan.FromSeconds(20);
});
builder.Services.AddHttpClient<IPhoneOtpSender, ZaloOtpService>((sp, client) =>
{
    var settings = sp.GetRequiredService<IOptions<ZaloOtpSettings>>().Value;
    client.BaseAddress = new Uri(settings.ApiBaseUrl.TrimEnd('/'));
    client.Timeout = TimeSpan.FromSeconds(20);
});

// Authentication & JWT
var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>()!;
var key = Encoding.UTF8.GetBytes(jwtSettings.Secret);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // Set true in production
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero
    };

    // Allow SignalR to read tokens from the query string when using WebSockets
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;

            if (!string.IsNullOrEmpty(accessToken) && 
                (path.StartsWithSegments("/hubs/chat") || path.StartsWithSegments("/hubs/notification")))
            {
                context.Token = accessToken;
            }

            return Task.CompletedTask;
        }
    };
});

// Authorization policies (RBAC)
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("ADMIN"));
    options.AddPolicy("CabinOwnerOnly", policy => policy.RequireRole("CABIN_OWNER"));
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("StrictPolicy", policy =>
    {
        policy.WithOrigins(
                "https://skvi.vn", 
                "https://admin.skvi.vn", 
                "http://localhost:5173",
                "https://localhost:5173",
                "http://localhost:5174",
                "https://localhost:5174",
                "https://lemon-water-0b4792900.2.azurestaticapps.net",
                "https://zealous-cliff-04c819000.7.azurestaticapps.net",
                "https://www.nhinanchualanh.vn",
                "https://nhinanchualanh.vn",
                "nhinanchualanh.vn"
              )
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); // Important for Cookies
    });
});

// SignalR
builder.Services.AddSignalR(options =>
{
    // Increase message size to allow base64 image payloads from chat (default 32KB)
    options.MaximumReceiveMessageSize = 200 * 1024; // 200 KB
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "SKVI E-Learning API",
        Version = "v1",
        Description = "API for SKVI E-Learning Platform - Admin, Instructor, and Student Management",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "SKVI Learning",
            Email = "support@skvi.vn"
        }
    });

    // Add JWT Authentication to Swagger
    options.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Enter 'Bearer' [space] and then your JWT token. Example: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'"
    });

    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Rate Limiter
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("AuthRateLimit", opt =>
    {
        opt.Window = TimeSpan.FromSeconds(10);
        opt.PermitLimit = 5; // 5 requests per 10 seconds per IP/User
        opt.QueueProcessingOrder = System.Threading.RateLimiting.QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 2;
    });

    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = 429;
        await context.HttpContext.Response.WriteAsync("Too many requests. Please try again later.", token);
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
// Automatically apply migrations on startup
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        context.Database.Migrate();
        Console.WriteLine("Database migrated successfully.");
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while migrating the database.");
        throw; // Re-throw the exception to fail the startup
    }
}

// Enable Swagger in all environments for API documentation
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "SKVI E-Learning API v1");
    options.RoutePrefix = "swagger"; // Access at /swagger
    options.DocumentTitle = "SKVI E-Learning API Documentation";
});

// CORS must come before UseHttpsRedirection
app.UseCors("StrictPolicy");

app.UseHttpsRedirection();

// Serve static files from wwwroot
app.UseStaticFiles();

// Serve static files from uploads folder
var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "uploads");
if (!Directory.Exists(uploadsPath))
{
    Directory.CreateDirectory(uploadsPath);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

// Cấu hình Hangfire Dashboard (chỉ active nếu Hangfire đã được đăng ký thành công)
try
{
    app.UseHangfireDashboard("/hangfire", new DashboardOptions
    {
        Authorization = new[] { new HangfireAuthorizationFilter() }
    });
}
catch (Exception ex)
{
    Console.Error.WriteLine($"[Hangfire] Dashboard unavailable: {ex.Message}");
}

app.MapControllers();
app.MapHub<SKVI.Infrastructure.Hubs.ChatHub>("/hubs/chat");
app.MapHub<SKVI.Infrastructure.Hubs.NotificationHub>("/hubs/notification");

app.Run();
