using System.Text;
using e_learning_server.Controllers;
using Microsoft.AspNetCore.Authentication.JwtBearer;
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
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Configuration
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));
builder.Services.Configure<SmtpSettings>(builder.Configuration.GetSection("SmtpSettings"));
builder.Services.Configure<BunnySettings>(builder.Configuration.GetSection("BunnySettings"));

// Services
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IVideoService, VideoService>();
builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<ICourseService, CourseService>();
builder.Services.AddScoped<ILessonService, LessonService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IInstructorService, InstructorService>();
builder.Services.AddScoped<IEnrollmentService, EnrollmentService>();
builder.Services.AddScoped<ILessonProgressService, LessonProgressService>();
builder.Services.AddScoped<ILessonProgressService, LessonProgressService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IArticleService, ArticleService>();
builder.Services.AddScoped<IMenuService, MenuService>();

// Guest Conversation Service (Singleton for in-memory storage)
builder.Services.AddSingleton<IGuestConversationService, GuestConversationService>();

// Background Services
builder.Services.AddHostedService<SKVI.Infrastructure.BackgroundServices.GuestConversationCleanupService>();

// Video Security Service (for signed URLs)
builder.Services.AddScoped<IVideoSecurityService>(sp =>
{
    var bunnySettings = sp.GetRequiredService<IOptions<BunnySettings>>().Value;
    return new VideoSecurityService(bunnySettings);
});

builder.Services.AddHttpClient<IBunnyStreamService, BunnyStreamService>();

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
                "https://salmon-river-0d2751800.4.azurestaticapps.net"
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

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<SKVI.Infrastructure.Hubs.ChatHub>("/hubs/chat");
app.MapHub<SKVI.Infrastructure.Hubs.NotificationHub>("/hubs/notification");

app.Run();
