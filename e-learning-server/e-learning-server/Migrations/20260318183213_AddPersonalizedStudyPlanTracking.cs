using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddPersonalizedStudyPlanTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserStudyPlans_UserId",
                table: "UserStudyPlans");

            migrationBuilder.DropIndex(
                name: "IX_DailyStudyTasks_PlanId",
                table: "DailyStudyTasks");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "UserStudyPlans",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<string>(
                name: "Constraints",
                table: "UserStudyPlans",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "CurrentStreakDays",
                table: "UserStudyPlans",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastCheckInDate",
                table: "UserStudyPlans",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LatestGuidanceMessage",
                table: "UserStudyPlans",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Motivation",
                table: "UserStudyPlans",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "PlanVersion",
                table: "UserStudyPlans",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<string>(
                name: "PreferredStudyTime",
                table: "UserStudyPlans",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "PrimaryCourseId",
                table: "UserStudyPlans",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TimeBudgetMinutesPerDay",
                table: "UserStudyPlans",
                type: "int",
                nullable: false,
                defaultValue: 45);

            migrationBuilder.AddColumn<int>(
                name: "ActualMinutesSpent",
                table: "DailyStudyTasks",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "DailyStudyTasks",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ConfidenceRating",
                table: "DailyStudyTasks",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DifficultyRating",
                table: "DailyStudyTasks",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EstimatedMinutes",
                table: "DailyStudyTasks",
                type: "int",
                nullable: false,
                defaultValue: 20);

            migrationBuilder.AddColumn<bool>(
                name: "NeedsSupport",
                table: "DailyStudyTasks",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ReflectionPrompt",
                table: "DailyStudyTasks",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "RelatedCourseId",
                table: "DailyStudyTasks",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "RelatedLessonPartId",
                table: "DailyStudyTasks",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SortOrder",
                table: "DailyStudyTasks",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "DailyStudyTasks",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "PLANNED");

            migrationBuilder.AddColumn<string>(
                name: "TaskType",
                table: "DailyStudyTasks",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "STUDY");

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "DailyStudyTasks",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "Task");

            migrationBuilder.Sql("UPDATE UserStudyPlans SET Status = 'ACTIVE' WHERE Status = 'Active';");
            migrationBuilder.Sql("UPDATE UserStudyPlans SET TimeBudgetMinutesPerDay = 45 WHERE TimeBudgetMinutesPerDay = 0;");
            migrationBuilder.Sql("UPDATE UserStudyPlans SET PlanVersion = 1 WHERE PlanVersion = 0;");
            migrationBuilder.Sql("UPDATE DailyStudyTasks SET Status = 'PLANNED' WHERE Status = '';");
            migrationBuilder.Sql("UPDATE DailyStudyTasks SET TaskType = 'STUDY' WHERE TaskType = '';");
            migrationBuilder.Sql("UPDATE DailyStudyTasks SET EstimatedMinutes = 20 WHERE EstimatedMinutes = 0;");
            migrationBuilder.Sql("UPDATE DailyStudyTasks SET Title = LEFT(Content, 200) WHERE Title = 'Task' OR Title = '';");

            migrationBuilder.CreateTable(
                name: "DailyStudyCheckIns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CheckInDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    MoodScore = table.Column<int>(type: "int", nullable: false),
                    EnergyScore = table.Column<int>(type: "int", nullable: false),
                    ConfidenceScore = table.Column<int>(type: "int", nullable: false),
                    ActualMinutesSpentToday = table.Column<int>(type: "int", nullable: true),
                    MinutesAvailableTomorrow = table.Column<int>(type: "int", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NeedsSupport = table.Column<bool>(type: "bit", nullable: false),
                    CoachAdvice = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyStudyCheckIns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DailyStudyCheckIns_UserStudyPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "UserStudyPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StudentSupportAlerts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DailyStudyTaskId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    DailyStudyCheckInId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Severity = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    SourceType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ResolvedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StudentSupportAlerts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StudentSupportAlerts_DailyStudyCheckIns_DailyStudyCheckInId",
                        column: x => x.DailyStudyCheckInId,
                        principalTable: "DailyStudyCheckIns",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_StudentSupportAlerts_DailyStudyTasks_DailyStudyTaskId",
                        column: x => x.DailyStudyTaskId,
                        principalTable: "DailyStudyTasks",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_StudentSupportAlerts_UserStudyPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "UserStudyPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_StudentSupportAlerts_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserStudyPlans_PrimaryCourseId",
                table: "UserStudyPlans",
                column: "PrimaryCourseId");

            migrationBuilder.CreateIndex(
                name: "IX_UserStudyPlans_UserId_Status",
                table: "UserStudyPlans",
                columns: new[] { "UserId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_DailyStudyTasks_PlanId_TaskDate_Status",
                table: "DailyStudyTasks",
                columns: new[] { "PlanId", "TaskDate", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_DailyStudyTasks_RelatedCourseId",
                table: "DailyStudyTasks",
                column: "RelatedCourseId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyStudyTasks_RelatedLessonPartId",
                table: "DailyStudyTasks",
                column: "RelatedLessonPartId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyStudyCheckIns_PlanId_CheckInDate",
                table: "DailyStudyCheckIns",
                columns: new[] { "PlanId", "CheckInDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StudentSupportAlerts_DailyStudyCheckInId",
                table: "StudentSupportAlerts",
                column: "DailyStudyCheckInId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentSupportAlerts_DailyStudyTaskId",
                table: "StudentSupportAlerts",
                column: "DailyStudyTaskId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentSupportAlerts_PlanId",
                table: "StudentSupportAlerts",
                column: "PlanId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentSupportAlerts_UserId_Status_CreatedAt",
                table: "StudentSupportAlerts",
                columns: new[] { "UserId", "Status", "CreatedAt" });

            migrationBuilder.AddForeignKey(
                name: "FK_DailyStudyTasks_Courses_RelatedCourseId",
                table: "DailyStudyTasks",
                column: "RelatedCourseId",
                principalTable: "Courses",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_DailyStudyTasks_LessonParts_RelatedLessonPartId",
                table: "DailyStudyTasks",
                column: "RelatedLessonPartId",
                principalTable: "LessonParts",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserStudyPlans_Courses_PrimaryCourseId",
                table: "UserStudyPlans",
                column: "PrimaryCourseId",
                principalTable: "Courses",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DailyStudyTasks_Courses_RelatedCourseId",
                table: "DailyStudyTasks");

            migrationBuilder.DropForeignKey(
                name: "FK_DailyStudyTasks_LessonParts_RelatedLessonPartId",
                table: "DailyStudyTasks");

            migrationBuilder.DropForeignKey(
                name: "FK_UserStudyPlans_Courses_PrimaryCourseId",
                table: "UserStudyPlans");

            migrationBuilder.DropTable(
                name: "StudentSupportAlerts");

            migrationBuilder.DropTable(
                name: "DailyStudyCheckIns");

            migrationBuilder.DropIndex(
                name: "IX_UserStudyPlans_PrimaryCourseId",
                table: "UserStudyPlans");

            migrationBuilder.DropIndex(
                name: "IX_UserStudyPlans_UserId_Status",
                table: "UserStudyPlans");

            migrationBuilder.DropIndex(
                name: "IX_DailyStudyTasks_PlanId_TaskDate_Status",
                table: "DailyStudyTasks");

            migrationBuilder.DropIndex(
                name: "IX_DailyStudyTasks_RelatedCourseId",
                table: "DailyStudyTasks");

            migrationBuilder.DropIndex(
                name: "IX_DailyStudyTasks_RelatedLessonPartId",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "Constraints",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "CurrentStreakDays",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "LastCheckInDate",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "LatestGuidanceMessage",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "Motivation",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "PlanVersion",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "PreferredStudyTime",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "PrimaryCourseId",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "TimeBudgetMinutesPerDay",
                table: "UserStudyPlans");

            migrationBuilder.DropColumn(
                name: "ActualMinutesSpent",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "ConfidenceRating",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "DifficultyRating",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "EstimatedMinutes",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "NeedsSupport",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "ReflectionPrompt",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "RelatedCourseId",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "RelatedLessonPartId",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "SortOrder",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "TaskType",
                table: "DailyStudyTasks");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "DailyStudyTasks");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "UserStudyPlans",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.CreateIndex(
                name: "IX_UserStudyPlans_UserId",
                table: "UserStudyPlans",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyStudyTasks_PlanId",
                table: "DailyStudyTasks",
                column: "PlanId");
        }
    }
}
