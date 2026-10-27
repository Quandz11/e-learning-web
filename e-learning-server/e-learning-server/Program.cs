using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using System.Text;
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
using SKVI.Infrastructure.Middlewares;

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
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<UserSessionService>();
builder.Services.AddSingleton<SessionConnections>();
if (builder.Configuration.GetValue<bool>("Features:EnableSessionHostedService", true))
{
    builder.Services.AddHostedService(sp => sp.GetRequiredService<SessionConnections>());
}
builder.Services.Configure<HubOptions>(options => options.AddFilter<SessionConnections>());
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPhoneAuthService, PhoneAuthService>();
builder.Services.AddScoped<IWellnessService, WellnessService>();
builder.Services.AddScoped<IRunningService, RunningService>();
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
if (builder.Configuration.GetValue<bool>("Features:EnableGuestCleanup", true))
{
    builder.Services.AddHostedService<SKVI.Infrastructure.BackgroundServices.GuestConversationCleanupService>();
}

// Configure Background Service Exception Behavior
builder.Services.Configure<HostOptions>(options =>
{
    options.BackgroundServiceExceptionBehavior = BackgroundServiceExceptionBehavior.Ignore;
});

// Hangfire Configuration
builder.Services.AddHangfire(configuration => configuration
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection"), new SqlServerStorageOptions
    {
        SchemaName = "dbo",
        CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
        SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
        QueuePollInterval = TimeSpan.Zero,
        UseRecommendedIsolationLevel = true,
        PrepareSchemaIfNecessary = true
    }));

if (builder.Configuration.GetValue<bool>("Features:EnableHangfireWorker", true))
{
    builder.Services.AddHangfireServer();
}

// Application Insights
var appInsightsConnStr = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]
    ?? builder.Configuration["ApplicationInsights:ConnectionString"];
if (!string.IsNullOrEmpty(appInsightsConnStr))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnStr;
    });
}

// Video Security Service
builder.Services.AddScoped<IVideoSecurityService>(sp =>
{
    var bunnySettings = sp.GetRequiredService<IOptions<BunnySettings>>().Value;
    return new VideoSecurityService(bunnySettings);
});

builder.Services.AddHttpClient<IBunnyStreamService, BunnyStreamService>()
    .AddStandardResilienceHandler(options =>
    {
        options.Retry.MaxRetryAttempts = 3;
        options.Retry.Delay = TimeSpan.FromSeconds(1);
        options.TotalRequestTimeout.Timeout = TimeSpan.FromSeconds(60);
        options.AttemptTimeout.Timeout = TimeSpan.FromSeconds(10); // must be <= SamplingDuration/2 (default 30s)
        options.CircuitBreaker.SamplingDuration = TimeSpan.FromSeconds(30);
    });
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

// Firebase Admin SDK Initialization
try
{
    var rawCredential = builder.Configuration["FIREBASE_CREDENTIAL_JSON"]
                        ?? builder.Configuration["APPSETTING_FIREBASE_CREDENTIAL_JSON"]
                        ?? builder.Configuration["Firebase:CredentialJson"]
                        ?? builder.Configuration["Firebase__CredentialJson"]
                        ?? builder.Configuration["FIREBASE_SERVICE_ACCOUNT_JSON"]
                        ?? builder.Configuration["APPSETTING_FIREBASE_SERVICE_ACCOUNT_JSON"]
                        ?? Environment.GetEnvironmentVariable("FIREBASE_CREDENTIAL_JSON")
                        ?? Environment.GetEnvironmentVariable("APPSETTING_FIREBASE_CREDENTIAL_JSON")
                        ?? Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_JSON")
                        ?? Environment.GetEnvironmentVariable("APPSETTING_FIREBASE_SERVICE_ACCOUNT_JSON");
    var firebaseCredPath = builder.Configuration["Firebase:CredentialFilePath"] ?? "firebase-service-account.json";

    Google.Apis.Auth.OAuth2.GoogleCredential? credential = null;

    if (!string.IsNullOrWhiteSpace(rawCredential))
    {
        var trimmed = rawCredential.Trim();
        string jsonContent = trimmed;
        if (!trimmed.StartsWith("{"))
        {
            try
            {
                var bytes = Convert.FromBase64String(trimmed);
                var decoded = Encoding.UTF8.GetString(bytes);
                if (decoded.Trim().StartsWith("{"))
                {
                    jsonContent = decoded.Trim();
                }
            }
            catch
            {
                // Fall back to using trimmed directly
            }
        }

        credential = Google.Apis.Auth.OAuth2.GoogleCredential.FromJson(jsonContent);
        Console.WriteLine("[Firebase] Admin SDK initialized successfully from environment variable (JSON string).");
    }
    else if (File.Exists(firebaseCredPath))
    {
        credential = Google.Apis.Auth.OAuth2.GoogleCredential.FromFile(firebaseCredPath);
        Console.WriteLine($"[Firebase] Admin SDK initialized successfully from file: '{firebaseCredPath}'.");
    }

    if (credential != null)
    {
        if (FirebaseAdmin.FirebaseApp.DefaultInstance == null)
        {
            FirebaseAdmin.FirebaseApp.Create(new FirebaseAdmin.AppOptions
            {
                Credential = credential
            });
            Console.WriteLine("[Firebase] Admin SDK instance created successfully.");
        }
    }
    else
    {
        Console.WriteLine($"[Firebase] Credential not found (checked FIREBASE_CREDENTIAL_JSON, APPSETTING_FIREBASE_CREDENTIAL_JSON, Firebase:CredentialJson, and '{firebaseCredPath}'). Push notifications via FCM will run in simulated mode.");
    }
}
catch (Exception ex)
{
    Console.Error.WriteLine($"[Firebase] Initialization warning: {ex.Message}");
}

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
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
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
        OnTokenValidated = async context =>
        {
            var user = context.Principal!;
            if (user.IsInRole("PRE_AUTH")) {
                if (context.Request.Path != "/api/auth/2fa/login-verify") context.Fail("PRE_AUTH_NOT_ALLOWED");
                return;
            }
            var sessions = context.HttpContext.RequestServices.GetRequiredService<UserSessionService>();
            if (!Guid.TryParse(user.FindFirstValue("sid"), out var sid) ||
                !Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var uid) ||
                !await sessions.IsActiveAsync(uid, sid, context.HttpContext.RequestAborted)) {
                context.HttpContext.Items["SessionRevoked"] = true;
                context.Fail("AUTH_SESSION_REVOKED");
                return;
            }
            await sessions.TouchAsync(sid, context.HttpContext.RequestAborted);
        },
        OnChallenge = async context => {
            if (context.HttpContext.Items.ContainsKey("SessionRevoked")) {
                context.HandleResponse();
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new { code = "AUTH_SESSION_REVOKED", message = "Phiên đăng nhập đã hết hiệu lực." });
            }
        },
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
                "https://nhinanchualanh.vn"
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

builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<Microsoft.AspNetCore.ResponseCompression.BrotliCompressionProvider>();
    options.Providers.Add<Microsoft.AspNetCore.ResponseCompression.GzipCompressionProvider>();
    options.MimeTypes = Microsoft.AspNetCore.ResponseCompression.ResponseCompressionDefaults.MimeTypes.Concat(
        ["application/json", "application/javascript", "text/css"]);
});
builder.Services.Configure<Microsoft.AspNetCore.ResponseCompression.BrotliCompressionProviderOptions>(options =>
    options.Level = System.IO.Compression.CompressionLevel.Fastest);
builder.Services.Configure<Microsoft.AspNetCore.ResponseCompression.GzipCompressionProviderOptions>(options =>
    options.Level = System.IO.Compression.CompressionLevel.Fastest);

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
        context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        context.HttpContext.Response.ContentType = "application/json; charset=utf-8";
        await context.HttpContext.Response.WriteAsJsonAsync(new
        {
            code = "TOO_MANY_REQUESTS",
            message = "Bạn đang thao tác quá nhanh. Vui lòng thử lại sau giây lát."
        }, token);
    };
});

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    service = "skvi-api"
})).AllowAnonymous();


// Configure the HTTP request pipeline.
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        if (app.Configuration.GetValue<bool>("Features:EnableAutoMigration", true))
        {
            context.Database.Migrate();
        }
        Console.WriteLine("Database migrated successfully.");
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while migrating the database.");
        throw;
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "SKVI E-Learning API v1");
        options.RoutePrefix = "swagger";
        options.DocumentTitle = "SKVI E-Learning API Documentation";
    });
}

// Security Headers Middleware
app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "DENY");
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
    context.Response.Headers.Append("X-XSS-Protection", "1; mode=block");
    await next();
});

app.UseResponseCompression();
app.UseCors("StrictPolicy");

app.UseMiddleware<RequestResponseLoggingMiddleware>();

app.UseHttpsRedirection();

app.UseDefaultFiles();
app.UseStaticFiles();

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
