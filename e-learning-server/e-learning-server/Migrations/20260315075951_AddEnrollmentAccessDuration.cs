using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddEnrollmentAccessDuration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AccessDurationDays",
                table: "Enrollments",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AccessExpiresAt",
                table: "Enrollments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DefaultAccessDurationDays",
                table: "Courses",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Enrollments_AccessExpiresAt",
                table: "Enrollments",
                column: "AccessExpiresAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Enrollments_AccessExpiresAt",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "AccessDurationDays",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "AccessExpiresAt",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "DefaultAccessDurationDays",
                table: "Courses");
        }
    }
}
