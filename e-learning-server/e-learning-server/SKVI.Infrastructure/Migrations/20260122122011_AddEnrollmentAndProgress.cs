using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.SKVI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEnrollmentAndProgress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Enrollments_Courses_CourseId",
                table: "Enrollments");

            migrationBuilder.DropForeignKey(
                name: "FK_Enrollments_Users_StudentId",
                table: "Enrollments");

            migrationBuilder.DropForeignKey(
                name: "FK_LessonProgresses_CourseLessons_LessonId",
                table: "LessonProgresses");

            migrationBuilder.DropIndex(
                name: "IX_LessonProgresses_LessonId",
                table: "LessonProgresses");

            migrationBuilder.DropIndex(
                name: "IX_Enrollments_StudentId_CourseId",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "Progress",
                table: "Enrollments");

            migrationBuilder.RenameColumn(
                name: "WatchedSeconds",
                table: "LessonProgresses",
                newName: "WatchedDuration");

            migrationBuilder.RenameColumn(
                name: "StudentId",
                table: "Enrollments",
                newName: "UserId");

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "LessonProgresses",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "CourseLessonId",
                table: "LessonProgresses",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastWatchedAt",
                table: "LessonProgresses",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "LastAccessedAt",
                table: "Enrollments",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "ProgressPercentage",
                table: "Enrollments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_CourseLessonId",
                table: "LessonProgresses",
                column: "CourseLessonId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_EnrollmentId_LessonId",
                table: "LessonProgresses",
                columns: new[] { "EnrollmentId", "LessonId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Enrollments_LastAccessedAt",
                table: "Enrollments",
                column: "LastAccessedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Enrollments_UserId",
                table: "Enrollments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Enrollments_UserId_CourseId",
                table: "Enrollments",
                columns: new[] { "UserId", "CourseId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Enrollments_Courses_CourseId",
                table: "Enrollments",
                column: "CourseId",
                principalTable: "Courses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Enrollments_Users_UserId",
                table: "Enrollments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_LessonProgresses_CourseLessons_CourseLessonId",
                table: "LessonProgresses",
                column: "CourseLessonId",
                principalTable: "CourseLessons",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Enrollments_Courses_CourseId",
                table: "Enrollments");

            migrationBuilder.DropForeignKey(
                name: "FK_Enrollments_Users_UserId",
                table: "Enrollments");

            migrationBuilder.DropForeignKey(
                name: "FK_LessonProgresses_CourseLessons_CourseLessonId",
                table: "LessonProgresses");

            migrationBuilder.DropIndex(
                name: "IX_LessonProgresses_CourseLessonId",
                table: "LessonProgresses");

            migrationBuilder.DropIndex(
                name: "IX_LessonProgresses_EnrollmentId_LessonId",
                table: "LessonProgresses");

            migrationBuilder.DropIndex(
                name: "IX_Enrollments_LastAccessedAt",
                table: "Enrollments");

            migrationBuilder.DropIndex(
                name: "IX_Enrollments_UserId",
                table: "Enrollments");

            migrationBuilder.DropIndex(
                name: "IX_Enrollments_UserId_CourseId",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "LessonProgresses");

            migrationBuilder.DropColumn(
                name: "CourseLessonId",
                table: "LessonProgresses");

            migrationBuilder.DropColumn(
                name: "LastWatchedAt",
                table: "LessonProgresses");

            migrationBuilder.DropColumn(
                name: "LastAccessedAt",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "ProgressPercentage",
                table: "Enrollments");

            migrationBuilder.RenameColumn(
                name: "WatchedDuration",
                table: "LessonProgresses",
                newName: "WatchedSeconds");

            migrationBuilder.RenameColumn(
                name: "UserId",
                table: "Enrollments",
                newName: "StudentId");

            migrationBuilder.AddColumn<decimal>(
                name: "Progress",
                table: "Enrollments",
                type: "decimal(5,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_LessonId",
                table: "LessonProgresses",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_Enrollments_StudentId_CourseId",
                table: "Enrollments",
                columns: new[] { "StudentId", "CourseId" });

            migrationBuilder.AddForeignKey(
                name: "FK_Enrollments_Courses_CourseId",
                table: "Enrollments",
                column: "CourseId",
                principalTable: "Courses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Enrollments_Users_StudentId",
                table: "Enrollments",
                column: "StudentId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_LessonProgresses_CourseLessons_LessonId",
                table: "LessonProgresses",
                column: "LessonId",
                principalTable: "CourseLessons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
