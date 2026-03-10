using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.SKVI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class SetDefaultEnrollmentStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Set all existing enrollments to ACTIVE (they were enrolled so they should be accessible)
            migrationBuilder.Sql("UPDATE [Enrollments] SET [Status] = 'ACTIVE' WHERE [Status] = '' OR [Status] IS NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
