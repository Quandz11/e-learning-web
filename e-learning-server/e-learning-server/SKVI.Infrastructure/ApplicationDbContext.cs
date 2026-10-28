using Microsoft.EntityFrameworkCore;
using SKVI.Domain.Entities;

namespace SKVI.Infrastructure;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    // Auth & User
    public DbSet<User> Users { get; set; }
    public DbSet<UserSession> UserSessions { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }
    public DbSet<ZaloOAuthToken> ZaloOAuthTokens { get; set; }
    public DbSet<UserDeviceToken> UserDeviceTokens { get; set; }
    public DbSet<UserReferral> UserReferrals { get; set; }
    public DbSet<ReferralTransaction> ReferralTransactions { get; set; }

    // Lead & Care
    public DbSet<Lead> Leads { get; set; }
    public DbSet<CareNote> CareNotes { get; set; }

    // Cabin
    public DbSet<Cabin> Cabins { get; set; }
    public DbSet<CabinMember> CabinMembers { get; set; }

    // Course
    public DbSet<Course> Courses { get; set; }
    public DbSet<Category> Categories { get; set; }
    public DbSet<Lesson> Lessons { get; set; }
    public DbSet<LessonPart> LessonParts { get; set; }
    public DbSet<CourseLesson> CourseLessons { get; set; }
    public DbSet<Video> Videos { get; set; }
    public DbSet<Document> Documents { get; set; }

    // Enrollment
    public DbSet<Enrollment> Enrollments { get; set; }
    public DbSet<LessonProgress> LessonProgresses { get; set; }
    public DbSet<Conversation> Conversations { get; set; }
    public DbSet<ConversationParticipant> ConversationParticipants { get; set; }
    public DbSet<Message> Messages { get; set; }

    // Payment
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<PaymentMethod> PaymentMethods { get; set; }
    public DbSet<PaymentTransaction> PaymentTransactions { get; set; }

    // Commission
    public DbSet<CommissionRule> CommissionRules { get; set; }
    public DbSet<CommissionLedger> CommissionLedgers { get; set; }
    public DbSet<Payout> Payouts { get; set; }

    // Chat
    public DbSet<Chat> Chats { get; set; }
    public DbSet<ChatMessage> ChatMessages { get; set; }
    public DbSet<Notification> Notifications { get; set; }

    // Articles
    public DbSet<Article> Articles { get; set; }
    public DbSet<ArticleCategory> ArticleCategories { get; set; }
    public DbSet<MenuItem> MenuItems { get; set; }

    // HomePage
    public DbSet<HomeVideoSection> HomeVideoSections { get; set; }

    // Audit
    public DbSet<AuditLog> AuditLogs { get; set; }

    // Quiz
    public DbSet<Quiz> Quizzes { get; set; }
    public DbSet<QuizQuestion> QuizQuestions { get; set; }
    public DbSet<QuizQuestionOption> QuizQuestionOptions { get; set; }
    public DbSet<QuizSubmission> QuizSubmissions { get; set; }
    public DbSet<QuizAnswer> QuizAnswers { get; set; }

    // Testimonials
    public DbSet<Testimonial> Testimonials { get; set; }

    // Why Choose Us
    public DbSet<WhyChooseUsItem> WhyChooseUsItems { get; set; }

    // Forum
    public DbSet<ForumCategory> ForumCategories { get; set; }
    public DbSet<ForumThread> ForumThreads { get; set; }
    public DbSet<ForumPost> ForumPosts { get; set; }

    // AI Feature
    public DbSet<AiSettings> AiSettings { get; set; }
    public DbSet<UserStudyPlan> UserStudyPlans { get; set; }
    public DbSet<DailyStudyTask> DailyStudyTasks { get; set; }
    public DbSet<DailyStudyCheckIn> DailyStudyCheckIns { get; set; }
    public DbSet<StudentSupportAlert> StudentSupportAlerts { get; set; }
    public DbSet<AiChatMessage> AiChatMessages { get; set; }
    public DbSet<WellnessPlan> WellnessPlans { get; set; }
    public DbSet<WellnessDailyLog> WellnessDailyLogs { get; set; }

    public DbSet<WellnessResource> WellnessResources { get; set; }
    public DbSet<WellnessResourceAssignment> WellnessResourceAssignments { get; set; }
    public DbSet<WellnessInsight> WellnessInsights { get; set; }
    public DbSet<WellnessCoachMessage> WellnessCoachMessages { get; set; }
    public DbSet<WellnessMealSuggestion> WellnessMealSuggestions { get; set; }
    public DbSet<WellnessSettings> WellnessSettings { get; set; }
    public DbSet<WellnessPackage> WellnessPackages { get; set; }
    public DbSet<WellnessUserPackage> WellnessUserPackages { get; set; }
    public DbSet<WellnessPackageLesson> WellnessPackageLessons { get; set; }
    public DbSet<WellnessDailyTask> WellnessDailyTasks { get; set; }
    public DbSet<UserReminder> UserReminders { get; set; }
    public DbSet<RunningActivity> RunningActivities { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
	modelBuilder.Entity<ZaloOAuthToken>(entity =>
{
    entity.ToTable("ZaloOAuthTokens");

    entity.HasKey(x => x.Id);

    entity.Property(x => x.AccessTokenEncrypted)
        .IsRequired()
        .HasColumnType("nvarchar(max)");

    entity.Property(x => x.RefreshTokenEncrypted)
        .IsRequired()
        .HasColumnType("nvarchar(max)");

    entity.Property(x => x.AccessTokenExpiresAtUtc)
        .HasColumnType("datetime2");

    entity.Property(x => x.UpdatedAtUtc)
        .HasColumnType("datetime2");

    entity.Property(x => x.RowVersion)
        .IsRowVersion();
});
        modelBuilder.Entity<Message>().HasIndex(m => new { m.SenderId, m.ConversationId, m.ClientMessageId })
            .IsUnique().HasFilter("[ClientMessageId] IS NOT NULL");
        modelBuilder.Entity<UserSession>().HasIndex(s => new { s.UserId, s.RevokedAt });
        modelBuilder.Entity<UserSession>().HasOne(s => s.User).WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<RefreshToken>().HasOne(t => t.Session).WithMany().HasForeignKey(t => t.SessionId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<RefreshToken>().Property(t => t.RevokedAt).IsConcurrencyToken();

        // Configure indexes and constraints as per requirements

        // Users
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Role);
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique()
            .HasFilter("[Email] IS NOT NULL");
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Phone)
            .HasFilter("[Phone] IS NOT NULL");
        modelBuilder.Entity<User>()
            .Property(u => u.Role)
            .IsRequired();

        modelBuilder.Entity<User>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(u => u.ReferredByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserDeviceToken>()
            .HasIndex(t => new { t.UserId, t.DeviceId })
            .IsUnique();

        modelBuilder.Entity<UserDeviceToken>()
            .HasIndex(t => t.Token);

        modelBuilder.Entity<UserDeviceToken>()
            .Property(t => t.Platform)
            .HasMaxLength(32);

        modelBuilder.Entity<UserDeviceToken>()
            .Property(t => t.DeviceId)
            .HasMaxLength(128);

        modelBuilder.Entity<UserDeviceToken>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserReferral>()
            .HasIndex(r => r.ReferralCode)
            .IsUnique();

        modelBuilder.Entity<UserReferral>()
            .HasIndex(r => r.DiscountCode)
            .IsUnique();

        modelBuilder.Entity<UserReferral>()
            .Property(r => r.DiscountPercent)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<UserReferral>()
            .HasOne(r => r.User)
            .WithMany(u => u.ReferralProfiles)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ReferralTransaction>()
            .HasIndex(t => t.ReferralCode);

        modelBuilder.Entity<ReferralTransaction>()
            .HasIndex(t => t.ReferredUserId)
            .IsUnique();

        modelBuilder.Entity<ReferralTransaction>()
            .HasOne(t => t.ReferrerUser)
            .WithMany(u => u.SentReferrals)
            .HasForeignKey(t => t.ReferrerUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ReferralTransaction>()
            .HasOne(t => t.ReferredUser)
            .WithMany(u => u.ReceivedReferrals)
            .HasForeignKey(t => t.ReferredUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ReferralTransaction>()
            .HasOne(t => t.UserReferral)
            .WithMany(r => r.ReferralTransactions)
            .HasForeignKey(t => t.UserReferralId)
            .OnDelete(DeleteBehavior.Cascade);

        // Leads
        modelBuilder.Entity<Lead>()
            .HasIndex(l => new { l.Status, l.AssignedCareId });

        // Orders
        modelBuilder.Entity<Order>()
            .HasIndex(o => new { o.Status, o.BuyerId });
        modelBuilder.Entity<Order>()
            .HasIndex(o => o.PayOSOrderCode)
            .IsUnique()
            .HasFilter("[PayOSOrderCode] IS NOT NULL");
        modelBuilder.Entity<Order>()
            .HasIndex(o => o.WellnessPackageId);
        modelBuilder.Entity<Order>()
            .Property(o => o.TotalAmount)
            .HasColumnType("decimal(18,2)");

        // Payment methods
        modelBuilder.Entity<PaymentMethod>()
            .HasIndex(pm => pm.Code)
            .IsUnique();

        // Enrollments - Optimized composite index + unique constraint
        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => new { e.UserId, e.CourseId })
            .IsUnique(); // Prevent duplicate enrollments
            
        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => e.UserId); // Fast lookup of user's enrollments
            
        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => e.CourseId); // Fast lookup of course enrollments
            
        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => e.LastAccessedAt); // For sorting recent courses

        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => e.AccessExpiresAt); // For expiry checks/filtering

        // LessonProgress - Composite index for fast lookup
        modelBuilder.Entity<LessonProgress>()
            .HasIndex(lp => new { lp.EnrollmentId, lp.LessonPartId })
            .IsUnique(); // One progress entry per lesson part per enrollment
            
        modelBuilder.Entity<LessonProgress>()
            .HasIndex(lp => lp.EnrollmentId); // Fast lookup of all lesson progress for enrollment

        // CommissionLedgers
        modelBuilder.Entity<CommissionLedger>()
            .HasIndex(c => new { c.CabinId, c.Status });
        modelBuilder.Entity<CommissionLedger>()
            .Property(c => c.Amount)
            .HasColumnType("decimal(18,2)");

        // Cabins
        modelBuilder.Entity<Cabin>()
            .Property(c => c.CommissionRate)
            .HasColumnType("decimal(5,2)");
        modelBuilder.Entity<Cabin>()
            .Property(c => c.WalletBalance)
            .HasColumnType("decimal(18,2)");
        modelBuilder.Entity<Cabin>()
            .HasIndex(c => c.ReferralCode)
            .IsUnique()
            .HasFilter("[ReferralCode] IS NOT NULL");

        // Notifications
        modelBuilder.Entity<Notification>()
            .HasIndex(n => new { n.UserId, n.IsRead });

        // Courses
        modelBuilder.Entity<Course>()
            .HasIndex(c => c.IsPublished);
        modelBuilder.Entity<Course>()
            .Property(c => c.Price)
            .HasColumnType("decimal(18,2)");
        
        // OrderItems
        modelBuilder.Entity<OrderItem>()
            .Property(o => o.Price)
            .HasColumnType("decimal(18,2)");

        // PaymentTransactions
        modelBuilder.Entity<PaymentTransaction>()
            .Property(p => p.Amount)
            .HasColumnType("decimal(18,2)");
        modelBuilder.Entity<PaymentTransaction>()
            .HasIndex(p => p.PaymentLinkId)
            .IsUnique()
            .HasFilter("[PaymentLinkId] IS NOT NULL");
            
        // Payouts
        modelBuilder.Entity<Payout>()
            .Property(p => p.Amount)
            .HasColumnType("decimal(18,2)");

        // CommissionRules
        modelBuilder.Entity<CommissionRule>()
            .Property(c => c.Rate)
            .HasColumnType("decimal(5,2)");
            
        // Course-Lesson (Many-to-Many)
        modelBuilder.Entity<CourseLesson>()
            .HasKey(cl => new { cl.CourseId, cl.LessonId });
            
        modelBuilder.Entity<CourseLesson>()
            .HasOne(cl => cl.Course)
            .WithMany(c => c.CourseLessons)
            .HasForeignKey(cl => cl.CourseId);

        modelBuilder.Entity<CourseLesson>()
            .HasOne(cl => cl.Lesson)
            .WithMany(l => l.CourseLessons)
            .HasForeignKey(cl => cl.LessonId);
            
        // Relationships configuration to prevent cycles
        
        // Enrollment - User
        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.User)
            .WithMany(u => u.Enrollments)
            .HasForeignKey(e => e.UserId)
            .OnDelete(DeleteBehavior.Restrict); // Prevent cascade cycle (User->Enrollment vs User->Course->Enrollment)

        // Enrollment - Course
        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.Course)
            .WithMany(c => c.Enrollments)
            .HasForeignKey(e => e.CourseId)
            .OnDelete(DeleteBehavior.Cascade); // Delete enrollments when course deleted
            
        // LessonProgress -Enrollment
        modelBuilder.Entity<LessonProgress>()
            .HasOne(lp => lp.Enrollment)
            .WithMany(e => e.LessonProgress)
            .HasForeignKey(lp => lp.EnrollmentId)
            .OnDelete(DeleteBehavior.Cascade); // Delete progress when enrollment deleted

        // Order - Buyer (User)
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Buyer)
            .WithMany(u => u.Orders)
            .HasForeignKey(o => o.BuyerId)
            .OnDelete(DeleteBehavior.Restrict);

        // Order - Cabin (optional attribution)
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Cabin)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CabinId)
            .OnDelete(DeleteBehavior.SetNull);

        // Order - WellnessPackage (optional attribution)
        modelBuilder.Entity<Order>()
            .HasOne(o => o.WellnessPackage)
            .WithMany()
            .HasForeignKey(o => o.WellnessPackageId)
            .OnDelete(DeleteBehavior.SetNull);

        // Lead - AssignedCare (User)
        modelBuilder.Entity<Lead>()
            .HasOne(l => l.AssignedCare)
            .WithMany()
            .HasForeignKey(l => l.AssignedCareId)
            .OnDelete(DeleteBehavior.Restrict);

        // Lead - AssignedCabin (Cabin)
        modelBuilder.Entity<Lead>()
            .HasOne(l => l.AssignedCabin)
            .WithMany(c => c.Leads)
            .HasForeignKey(l => l.AssignedCabinId)
            .OnDelete(DeleteBehavior.Restrict);

        // CommissionLedger - Cabin
        modelBuilder.Entity<CommissionLedger>()
            .HasOne(c => c.Cabin)
            .WithMany(cb => cb.CommissionLedgers)
            .HasForeignKey(c => c.CabinId)
            .OnDelete(DeleteBehavior.Restrict);

        // Enrollment - Order (optional paid/free source tracking)
        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.Order)
            .WithMany()
            .HasForeignKey(e => e.OrderId)
            .OnDelete(DeleteBehavior.SetNull);

        // Articles
        modelBuilder.Entity<Article>()
            .HasIndex(a => a.Slug)
            .IsUnique();
        
        modelBuilder.Entity<Article>()
            .HasIndex(a => new { a.IsPublished, a.PublishedAt });
        
        modelBuilder.Entity<Article>()
            .HasIndex(a => a.CategoryId);

        modelBuilder.Entity<Article>()
            .HasOne(a => a.Author)
            .WithMany()
            .HasForeignKey(a => a.AuthorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Article>()
            .HasOne(a => a.Category)
            .WithMany(c => c.Articles)
            .HasForeignKey(a => a.CategoryId)
            .OnDelete(DeleteBehavior.SetNull);

        // ArticleCategories
        modelBuilder.Entity<ArticleCategory>()
            .HasIndex(c => c.Slug)
            .IsUnique();

        // MenuItems
        modelBuilder.Entity<MenuItem>()
            .HasIndex(m => new { m.MenuLocation, m.DisplayOrder });

        modelBuilder.Entity<MenuItem>()
            .HasOne(m => m.Parent)
            .WithMany(m => m.Children)
            .HasForeignKey(m => m.ParentId)
            .OnDelete(DeleteBehavior.Restrict);

        // HomeVideoSection
        modelBuilder.Entity<HomeVideoSection>()
            .HasOne(h => h.Video)
            .WithMany()
            .HasForeignKey(h => h.VideoId)
            .OnDelete(DeleteBehavior.SetNull);

        // Quiz Configuration
        modelBuilder.Entity<QuizQuestion>()
            .HasOne(q => q.Quiz)
            .WithMany(qz => qz.Questions)
            .HasForeignKey(q => q.QuizId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<QuizQuestionOption>()
            .HasOne(o => o.Question)
            .WithMany(q => q.Options)
            .HasForeignKey(o => o.QuestionId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<QuizSubmission>()
            .HasOne(s => s.Quiz)
            .WithMany(q => q.Submissions)
            .HasForeignKey(s => s.QuizId)
            .OnDelete(DeleteBehavior.Restrict);
            
        modelBuilder.Entity<QuizSubmission>()
            .HasOne(s => s.User)
            .WithMany()
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<QuizAnswer>()
            .HasOne(a => a.Submission)
            .WithMany(s => s.Answers)
            .HasForeignKey(a => a.SubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<QuizAnswer>()
            .HasOne(a => a.Question)
            .WithMany()
            .HasForeignKey(a => a.QuestionId)
            .OnDelete(DeleteBehavior.Restrict);
            
        modelBuilder.Entity<QuizAnswer>()
            .HasOne(a => a.SelectedOption)
            .WithMany()
            .HasForeignKey(a => a.SelectedOptionId)
            .OnDelete(DeleteBehavior.Restrict);

        // Forum Configuration
        modelBuilder.Entity<ForumCategory>()
            .HasIndex(fc => fc.Order);

        modelBuilder.Entity<ForumThread>()
            .HasIndex(ft => new { ft.CategoryId, ft.LastPostAt });

        modelBuilder.Entity<ForumThread>()
            .HasIndex(ft => ft.AuthorId);

        modelBuilder.Entity<ForumThread>()
            .HasOne(ft => ft.Category)
            .WithMany(fc => fc.Threads)
            .HasForeignKey(ft => ft.CategoryId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ForumThread>()
            .HasOne(ft => ft.Author)
            .WithMany()
            .HasForeignKey(ft => ft.AuthorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ForumPost>()
            .HasIndex(fp => new { fp.ThreadId, fp.CreatedAt });

        modelBuilder.Entity<ForumPost>()
            .HasIndex(fp => fp.AuthorId);

        modelBuilder.Entity<ForumPost>()
            .HasOne(fp => fp.Thread)
            .WithMany(ft => ft.Posts)
            .HasForeignKey(fp => fp.ThreadId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ForumPost>()
            .HasOne(fp => fp.Author)
            .WithMany()
            .HasForeignKey(fp => fp.AuthorId)
            .OnDelete(DeleteBehavior.Restrict);

        // AI Feature configurations
        modelBuilder.Entity<AiSettings>()
            .HasIndex(s => s.IsEnabled);

        modelBuilder.Entity<WellnessSettings>()
            .HasIndex(s => s.UpdatedAt);

        modelBuilder.Entity<WellnessPackage>()
            .HasIndex(p => p.Code)
            .IsUnique();

        modelBuilder.Entity<WellnessPackage>()
            .HasIndex(p => new { p.IsActive, p.SortOrder });

        modelBuilder.Entity<WellnessUserPackage>()
            .HasIndex(p => new { p.UserId, p.Status, p.ExpiresAt });

        modelBuilder.Entity<WellnessUserPackage>()
            .HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessUserPackage>()
            .HasOne(p => p.Package)
            .WithMany(p => p.UserPackages)
            .HasForeignKey(p => p.PackageId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<WellnessUserPackage>()
            .HasOne(p => p.GrantedByUser)
            .WithMany()
            .HasForeignKey(p => p.GrantedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserStudyPlan>()
            .HasIndex(p => new { p.UserId, p.Status });

        modelBuilder.Entity<UserStudyPlan>()
            .HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserStudyPlan>()
            .HasOne(p => p.PrimaryCourse)
            .WithMany()
            .HasForeignKey(p => p.PrimaryCourseId)
            .OnDelete(DeleteBehavior.ClientSetNull);

        modelBuilder.Entity<DailyStudyTask>()
            .HasIndex(t => new { t.PlanId, t.TaskDate, t.Status });

        modelBuilder.Entity<DailyStudyTask>()
            .HasOne(t => t.Plan)
            .WithMany(p => p.DailyTasks)
            .HasForeignKey(t => t.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<DailyStudyTask>()
            .HasOne(t => t.RelatedCourse)
            .WithMany()
            .HasForeignKey(t => t.RelatedCourseId)
            .OnDelete(DeleteBehavior.NoAction);

        modelBuilder.Entity<DailyStudyTask>()
            .HasOne(t => t.RelatedLessonPart)
            .WithMany()
            .HasForeignKey(t => t.RelatedLessonPartId)
            .OnDelete(DeleteBehavior.NoAction);

        modelBuilder.Entity<DailyStudyCheckIn>()
            .HasIndex(c => new { c.PlanId, c.CheckInDate })
            .IsUnique();

        modelBuilder.Entity<DailyStudyCheckIn>()
            .HasOne(c => c.Plan)
            .WithMany(p => p.DailyCheckIns)
            .HasForeignKey(c => c.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<StudentSupportAlert>()
            .HasIndex(a => new { a.UserId, a.Status, a.CreatedAt });

        modelBuilder.Entity<StudentSupportAlert>()
            .HasOne(a => a.User)
            .WithMany()
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<StudentSupportAlert>()
            .HasOne(a => a.Plan)
            .WithMany(p => p.SupportAlerts)
            .HasForeignKey(a => a.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<StudentSupportAlert>()
            .HasOne(a => a.DailyStudyTask)
            .WithMany()
            .HasForeignKey(a => a.DailyStudyTaskId)
            .OnDelete(DeleteBehavior.NoAction);

        modelBuilder.Entity<StudentSupportAlert>()
            .HasOne(a => a.DailyStudyCheckIn)
            .WithMany()
            .HasForeignKey(a => a.DailyStudyCheckInId)
            .OnDelete(DeleteBehavior.NoAction);

        modelBuilder.Entity<AiChatMessage>()
            .HasIndex(m => m.UserId);

        modelBuilder.Entity<AiChatMessage>()
            .HasOne(m => m.User)
            .WithMany()
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessPlan>()
            .HasIndex(p => new { p.UserId, p.Status });

        modelBuilder.Entity<WellnessPlan>()
            .HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessDailyLog>()
            .HasIndex(l => new { l.PlanId, l.LogDate })
            .IsUnique();

        modelBuilder.Entity<WellnessDailyLog>()
            .HasOne(l => l.Plan)
            .WithMany(p => p.DailyLogs)
            .HasForeignKey(l => l.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessInsight>()
            .HasIndex(i => new { i.PlanId, i.InsightDate })
            .IsUnique();

        modelBuilder.Entity<WellnessInsight>()
            .HasOne(i => i.Plan)
            .WithMany(p => p.Insights)
            .HasForeignKey(i => i.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessCoachMessage>()
            .HasIndex(m => new { m.PlanId, m.CreatedAt });

        modelBuilder.Entity<WellnessCoachMessage>()
            .HasOne(m => m.Plan)
            .WithMany(p => p.CoachMessages)
            .HasForeignKey(m => m.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessMealSuggestion>()
            .HasIndex(m => new { m.PlanId, m.CreatedAt });

        modelBuilder.Entity<WellnessMealSuggestion>()
            .HasOne(m => m.Plan)
            .WithMany(p => p.MealSuggestions)
            .HasForeignKey(m => m.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessResource>()
            .HasIndex(r => new { r.ResourceType, r.IsActive });

        modelBuilder.Entity<WellnessResourceAssignment>()
            .HasIndex(a => new { a.PlanId, a.AssignmentDate })
            .IsUnique();

        modelBuilder.Entity<WellnessResourceAssignment>()
            .HasOne(a => a.Plan)
            .WithMany(p => p.ResourceAssignments)
            .HasForeignKey(a => a.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessResourceAssignment>()
            .HasOne(a => a.MeditationResource)
            .WithMany()
            .HasForeignKey(a => a.MeditationResourceId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<WellnessResourceAssignment>()
            .HasOne(a => a.BreathingResource)
            .WithMany()
            .HasForeignKey(a => a.BreathingResourceId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<WellnessResourceAssignment>()
            .HasOne(a => a.WorkoutResource)
            .WithMany()
            .HasForeignKey(a => a.WorkoutResourceId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<WellnessPackageLesson>()
            .HasIndex(l => new { l.WellnessPackageId, l.DayIndex, l.SortOrder });

        modelBuilder.Entity<WellnessPackageLesson>()
            .HasOne(l => l.WellnessPackage)
            .WithMany(p => p.PackageLessons)
            .HasForeignKey(l => l.WellnessPackageId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WellnessDailyTask>()
            .HasIndex(t => new { t.WellnessPlanId, t.TaskDate });

        modelBuilder.Entity<WellnessDailyTask>()
            .HasOne(t => t.WellnessPlan)
            .WithMany(p => p.DailyTasks)
            .HasForeignKey(t => t.WellnessPlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<RunningActivity>()
            .HasIndex(r => r.UserId);

        modelBuilder.Entity<RunningActivity>()
            .HasIndex(r => r.ActivityDate);

        modelBuilder.Entity<RunningActivity>()
            .HasIndex(r => new { r.UserId, r.ActivityDate });

        modelBuilder.Entity<RunningActivity>()
            .HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);
            
        // Relationships are automatically configured by EF Core conventions based on navigation properties,
        // but explicit configuration can be added here if needed.
    }
}
