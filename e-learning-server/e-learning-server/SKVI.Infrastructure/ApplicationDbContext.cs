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
    public DbSet<RefreshToken> RefreshTokens { get; set; }

    // Lead & Care
    public DbSet<Lead> Leads { get; set; }
    public DbSet<CareNote> CareNotes { get; set; }

    // Cabin
    public DbSet<Cabin> Cabins { get; set; }
    public DbSet<CabinMember> CabinMembers { get; set; }

    // Course
    public DbSet<Course> Courses { get; set; }
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

    // Audit
    public DbSet<AuditLog> AuditLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure indexes and constraints as per requirements

        // Users
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Role);
        modelBuilder.Entity<User>()
            .Property(u => u.Role)
            .IsRequired();

        // Leads
        modelBuilder.Entity<Lead>()
            .HasIndex(l => new { l.Status, l.AssignedCareId });

        // Orders
        modelBuilder.Entity<Order>()
            .HasIndex(o => new { o.Status, o.BuyerId });
        modelBuilder.Entity<Order>()
            .Property(o => o.TotalAmount)
            .HasColumnType("decimal(18,2)");

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

        // Courses
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
            
        // Relationships are automatically configured by EF Core conventions based on navigation properties,
        // but explicit configuration can be added here if needed.
    }
}
