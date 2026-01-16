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

    // Chat
    public DbSet<Chat> Chats { get; set; }
    public DbSet<ChatMessage> ChatMessages { get; set; }
    public DbSet<Notification> Notifications { get; set; }

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

        // Enrollments
        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => new { e.StudentId, e.CourseId });
        modelBuilder.Entity<Enrollment>()
            .Property(e => e.Progress)
            .HasColumnType("decimal(5,2)");

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
            
        // Relationships configuration to prevent cycles
        
        // Enrollment - Student (User)
        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.Student)
            .WithMany(u => u.Enrollments)
            .HasForeignKey(e => e.StudentId)
            .OnDelete(DeleteBehavior.Restrict);

        // Enrollment - Course
        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.Course)
            .WithMany(c => c.Enrollments)
            .HasForeignKey(e => e.CourseId)
            .OnDelete(DeleteBehavior.Restrict);

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
            
        // Relationships are automatically configured by EF Core conventions based on navigation properties,
        // but explicit configuration can be added here if needed.
    }
}
