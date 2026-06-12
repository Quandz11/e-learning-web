using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddWellnessRoadmap : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WellnessDailyTasks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    WellnessPlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    DayIndex = table.Column<int>(type: "int", nullable: false),
                    TaskDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    EstimatedMinutes = table.Column<int>(type: "int", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsCompleted = table.Column<bool>(type: "bit", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessDailyTasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessDailyTasks_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_WellnessDailyTasks_WellnessPlans_WellnessPlanId",
                        column: x => x.WellnessPlanId,
                        principalTable: "WellnessPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WellnessPackageLessons",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    WellnessPackageId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DayIndex = table.Column<int>(type: "int", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessPackageLessons", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessPackageLessons_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WellnessPackageLessons_WellnessPackages_WellnessPackageId",
                        column: x => x.WellnessPackageId,
                        principalTable: "WellnessPackages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessDailyTasks_LessonId",
                table: "WellnessDailyTasks",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessDailyTasks_WellnessPlanId_TaskDate",
                table: "WellnessDailyTasks",
                columns: new[] { "WellnessPlanId", "TaskDate" });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessPackageLessons_LessonId",
                table: "WellnessPackageLessons",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessPackageLessons_WellnessPackageId_DayIndex_SortOrder",
                table: "WellnessPackageLessons",
                columns: new[] { "WellnessPackageId", "DayIndex", "SortOrder" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WellnessDailyTasks");

            migrationBuilder.DropTable(
                name: "WellnessPackageLessons");
        }
    }
}
