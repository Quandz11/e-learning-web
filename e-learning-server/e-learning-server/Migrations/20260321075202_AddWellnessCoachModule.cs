using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddWellnessCoachModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WellnessPlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PackageType = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EndDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    FastingHours = table.Column<int>(type: "int", nullable: false),
                    EatingHours = table.Column<int>(type: "int", nullable: false),
                    DailyFastStartMinuteOfDay = table.Column<int>(type: "int", nullable: false),
                    Timezone = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    StartWeightKg = table.Column<decimal>(type: "decimal(6,2)", nullable: false),
                    TargetWeightKg = table.Column<decimal>(type: "decimal(6,2)", nullable: false),
                    LatestWeightKg = table.Column<decimal>(type: "decimal(6,2)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    LastInsightAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UpgradeSuggestionLevel = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessPlans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessPlans_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WellnessResources",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ResourceType = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    Title = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    Url = table.Column<string>(type: "nvarchar(1024)", maxLength: 1024, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1024)", maxLength: 1024, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    RotationWeight = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessResources", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WellnessCoachMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Role = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    MessageType = table.Column<string>(type: "nvarchar(24)", maxLength: 24, nullable: false),
                    ContentEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessCoachMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessCoachMessages_WellnessPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "WellnessPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WellnessDailyLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LogDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AteAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    WaterMl = table.Column<int>(type: "int", nullable: false),
                    WorkoutMinutes = table.Column<int>(type: "int", nullable: false),
                    WorkoutType = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    CurrentWeightKg = table.Column<decimal>(type: "decimal(6,2)", nullable: true),
                    NotesEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessDailyLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessDailyLogs_WellnessPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "WellnessPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WellnessInsights",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    InsightDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SummaryEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TipEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    RisksEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    GeneratedBy = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessInsights", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessInsights_WellnessPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "WellnessPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WellnessMealSuggestions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IngredientsEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Servings = table.Column<int>(type: "int", nullable: false),
                    SuggestedMenuEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NutritionNotesEncrypted = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessMealSuggestions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessMealSuggestions_WellnessPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "WellnessPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WellnessResourceAssignments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AssignmentDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    MeditationResourceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BreathingResourceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    WorkoutResourceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SelectionStrategy = table.Column<string>(type: "nvarchar(24)", maxLength: 24, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessResourceAssignments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessResourceAssignments_WellnessPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "WellnessPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WellnessResourceAssignments_WellnessResources_BreathingResourceId",
                        column: x => x.BreathingResourceId,
                        principalTable: "WellnessResources",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WellnessResourceAssignments_WellnessResources_MeditationResourceId",
                        column: x => x.MeditationResourceId,
                        principalTable: "WellnessResources",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WellnessResourceAssignments_WellnessResources_WorkoutResourceId",
                        column: x => x.WorkoutResourceId,
                        principalTable: "WellnessResources",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessCoachMessages_PlanId_CreatedAt",
                table: "WellnessCoachMessages",
                columns: new[] { "PlanId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessDailyLogs_PlanId_LogDate",
                table: "WellnessDailyLogs",
                columns: new[] { "PlanId", "LogDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WellnessInsights_PlanId_InsightDate",
                table: "WellnessInsights",
                columns: new[] { "PlanId", "InsightDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WellnessMealSuggestions_PlanId_CreatedAt",
                table: "WellnessMealSuggestions",
                columns: new[] { "PlanId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessPlans_UserId_Status",
                table: "WellnessPlans",
                columns: new[] { "UserId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessResourceAssignments_BreathingResourceId",
                table: "WellnessResourceAssignments",
                column: "BreathingResourceId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessResourceAssignments_MeditationResourceId",
                table: "WellnessResourceAssignments",
                column: "MeditationResourceId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessResourceAssignments_PlanId_AssignmentDate",
                table: "WellnessResourceAssignments",
                columns: new[] { "PlanId", "AssignmentDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WellnessResourceAssignments_WorkoutResourceId",
                table: "WellnessResourceAssignments",
                column: "WorkoutResourceId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessResources_ResourceType_IsActive",
                table: "WellnessResources",
                columns: new[] { "ResourceType", "IsActive" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WellnessCoachMessages");

            migrationBuilder.DropTable(
                name: "WellnessDailyLogs");

            migrationBuilder.DropTable(
                name: "WellnessInsights");

            migrationBuilder.DropTable(
                name: "WellnessMealSuggestions");

            migrationBuilder.DropTable(
                name: "WellnessResourceAssignments");

            migrationBuilder.DropTable(
                name: "WellnessPlans");

            migrationBuilder.DropTable(
                name: "WellnessResources");
        }
    }
}
