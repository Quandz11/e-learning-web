using Microsoft.EntityFrameworkCore;
using SKVI.Domain.Entities.Admin;
using SKVI.Domain.Entities.Auth;
using SKVI.Domain.Entities.Cabin;
using SKVI.Domain.Entities.Chat;
using SKVI.Domain.Entities.Commission;
using SKVI.Domain.Entities.Course;
using SKVI.Domain.Entities.Enrollment;
using SKVI.Domain.Entities.Lead;
using SKVI.Domain.Entities.Notification;
using SKVI.Domain.Entities.Payment;
using SKVI.Domain.Enums;

namespace SKVI.Infrastructure.Data;

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

    // Course & Content
    public DbSet<Course> Courses { get; set; }
    public DbSet<CourseSection> CourseSections { get; set; }
    public DbSet<CourseLesson> CourseLessons { get; set; }
    public DbSet<Video> Videos { get; set; }

    // Enrollment
    public DbSet<Enrollment> Enrollments { get; set; }
    public DbSet<LessonProgress> LessonProgresses { get; set; }

    // Payment
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<PaymentMethod> PaymentMethods { get; set; }
    public DbSet<PaymentTransaction> PaymentTransactions { get; set; }

    // Commission
    public DbSet<CommissionRule> CommissionRules { get; set; }
    public DbSet<CommissionLedger> CommissionLedgers { get; set; }
    public DbSet<Payout> Payouts { get; set; }

    // Chat & Notification
    public DbSet<Chat> Chats { get; set; }
    public DbSet<ChatMessage> ChatMessages { get; set; }
    public DbSet<SKVI.Domain.Entities.Notification.Notification> Notifications { get; set; }

    // Admin
    public DbSet<AuditLog> AuditLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User entity
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Email).HasMaxLength(255);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.FullName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.PasswordHash).IsRequired();
            entity.Property(e => e.Role).HasConversion<string>().HasMaxLength(20).IsRequired();
            entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);

            entity.HasIndex(e => e.Email).IsUnique().HasFilter("[Email] IS NOT NULL");
            entity.HasIndex(e => e.Phone).IsUnique().HasFilter("[Phone] IS NOT NULL");
            entity.HasIndex(e => e.Role);
            
            entity.HasQueryFilter(e => !e.IsDeleted);

            entity.HasMany(e => e.RefreshTokens)
                .WithOne(rt => rt.User)
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure RefreshToken entity
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TokenHash).IsRequired();
            entity.Property(e => e.DeviceId).HasMaxLength(255);
            entity.Property(e => e.IpAddress).HasMaxLength(50);
        });

        // Configure Lead entity
        modelBuilder.Entity<Lead>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.FullName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.ZaloUserId).HasMaxLength(255);
            entity.Property(e => e.Source).HasConversion<string>().HasMaxLength(50);
            entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);

            entity.HasIndex(e => new { e.Status, e.AssignedCareId });

            entity.HasOne(e => e.AssignedCare)
                .WithMany()
                .HasForeignKey(e => e.AssignedCareId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.AssignedCabin)
                .WithMany(c => c.Leads)
                .HasForeignKey(e => e.AssignedCabinId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure CareNote entity
        modelBuilder.Entity<CareNote>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Note).IsRequired();

            entity.HasOne(e => e.Lead)
                .WithMany(l => l.CareNotes)
                .HasForeignKey(e => e.LeadId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Student)
                .WithMany()
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Care)
                .WithMany()
                .HasForeignKey(e => e.CareId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Cabin entity
        modelBuilder.Entity<Cabin>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(255).IsRequired();
            entity.Property(e => e.CommissionRate).HasColumnType("decimal(5,2)");
            entity.Property(e => e.WalletBalance).HasColumnType("decimal(18,2)");

            entity.HasOne(e => e.Owner)
                .WithMany()
                .HasForeignKey(e => e.OwnerUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure CabinMember entity
        modelBuilder.Entity<CabinMember>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.HasOne(e => e.ParentCabin)
                .WithMany()
                .HasForeignKey(e => e.ParentCabinId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.ChildCabin)
                .WithMany()
                .HasForeignKey(e => e.ChildCabinId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Course entity
        modelBuilder.Entity<Course>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Price).HasColumnType("decimal(18,2)");

            entity.HasOne(e => e.Lecturer)
                .WithMany()
                .HasForeignKey(e => e.LecturerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(e => e.Sections)
                .WithOne(s => s.Course)
                .HasForeignKey(s => s.CourseId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure CourseSection entity
        modelBuilder.Entity<CourseSection>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(255).IsRequired();
        });

        // Configure CourseLesson entity
        modelBuilder.Entity<CourseLesson>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(255).IsRequired();

            entity.HasOne(e => e.Section)
                .WithMany(s => s.Lessons)
                .HasForeignKey(e => e.SectionId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Video)
                .WithMany(v => v.Lessons)
                .HasForeignKey(e => e.VideoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Video entity
        modelBuilder.Entity<Video>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.BunnyLibraryId).HasMaxLength(255).IsRequired();
            entity.Property(e => e.BunnyVideoId).HasMaxLength(255).IsRequired();
        });

        // Configure Enrollment entity
        modelBuilder.Entity<Enrollment>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Progress).HasColumnType("decimal(5,2)");

            entity.HasIndex(e => new { e.StudentId, e.CourseId });

            entity.HasOne(e => e.Student)
                .WithMany()
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Course)
                .WithMany(c => c.Enrollments)
                .HasForeignKey(e => e.CourseId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure LessonProgress entity
        modelBuilder.Entity<LessonProgress>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.HasOne(e => e.Enrollment)
                .WithMany(en => en.LessonProgresses)
                .HasForeignKey(e => e.EnrollmentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Lesson)
                .WithMany(l => l.LessonProgresses)
                .HasForeignKey(e => e.LessonId)
                .OnDelete(DeleteBehavior.Restrict); // Changed from Cascade to Restrict to avoid multiple cascade paths
        });

        // Configure Order entity
        modelBuilder.Entity<Order>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TotalAmount).HasColumnType("decimal(18,2)");
            entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);

            entity.HasIndex(e => new { e.Status, e.BuyerId });

            entity.HasOne(e => e.Buyer)
                .WithMany()
                .HasForeignKey(e => e.BuyerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure OrderItem entity
        modelBuilder.Entity<OrderItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Price).HasColumnType("decimal(18,2)");

            entity.HasOne(e => e.Order)
                .WithMany(o => o.OrderItems)
                .HasForeignKey(e => e.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Course)
                .WithMany(c => c.OrderItems)
                .HasForeignKey(e => e.CourseId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure PaymentMethod entity
        modelBuilder.Entity<PaymentMethod>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Code).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Name).HasMaxLength(255).IsRequired();
        });

        // Configure PaymentTransaction entity
        modelBuilder.Entity<PaymentTransaction>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ProviderTransactionId).HasMaxLength(255);
            entity.Property(e => e.Amount).HasColumnType("decimal(18,2)");
            entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);

            entity.HasOne(e => e.Order)
                .WithMany(o => o.PaymentTransactions)
                .HasForeignKey(e => e.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.PaymentMethod)
                .WithMany(pm => pm.PaymentTransactions)
                .HasForeignKey(e => e.PaymentMethodId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure CommissionRule entity
        modelBuilder.Entity<CommissionRule>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Rate).HasColumnType("decimal(5,2)");

            entity.HasOne(e => e.Cabin)
                .WithMany()
                .HasForeignKey(e => e.CabinId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Course)
                .WithMany()
                .HasForeignKey(e => e.CourseId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure CommissionLedger entity
        modelBuilder.Entity<CommissionLedger>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasColumnType("decimal(18,2)");
            entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);

            entity.HasIndex(e => new { e.CabinId, e.Status });

            entity.HasOne(e => e.Cabin)
                .WithMany(c => c.CommissionLedgers)
                .HasForeignKey(e => e.CabinId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Order)
                .WithMany(o => o.CommissionLedgers)
                .HasForeignKey(e => e.OrderId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Payout entity
        modelBuilder.Entity<Payout>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasColumnType("decimal(18,2)");
            entity.Property(e => e.BankName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.BankAccount).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(20);

            entity.HasOne(e => e.Cabin)
                .WithMany()
                .HasForeignKey(e => e.CabinId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Chat entity
        modelBuilder.Entity<Chat>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.HasOne(e => e.Student)
                .WithMany()
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Care)
                .WithMany()
                .HasForeignKey(e => e.CareId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure ChatMessage entity
        modelBuilder.Entity<ChatMessage>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Message).IsRequired();

            entity.HasOne(e => e.Chat)
                .WithMany(c => c.Messages)
                .HasForeignKey(e => e.ChatId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Sender)
                .WithMany()
                .HasForeignKey(e => e.SenderId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Notification entity
        modelBuilder.Entity<SKVI.Domain.Entities.Notification.Notification>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Content).IsRequired();

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure AuditLog entity
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Action).HasMaxLength(255).IsRequired();
            entity.Property(e => e.TargetTable).HasMaxLength(255).IsRequired();

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });
    }

    public override int SaveChanges()
    {
        UpdateTimestamps();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateTimestamps()
    {
        var entities = ChangeTracker.Entries()
            .Where(e => e.Entity is Domain.Common.BaseEntity && (e.State == EntityState.Added || e.State == EntityState.Modified));

        foreach (var entity in entities)
        {
            var baseEntity = (Domain.Common.BaseEntity)entity.Entity;
            
            if (entity.State == EntityState.Added)
            {
                baseEntity.CreatedAt = DateTime.UtcNow;
            }
            
            if (entity.State == EntityState.Modified)
            {
                baseEntity.UpdatedAt = DateTime.UtcNow;
            }
        }
    }
}
