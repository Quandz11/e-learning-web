using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddRunningActivityFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RunningActivities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DistanceKm = table.Column<decimal>(type: "decimal(8,3)", precision: 8, scale: 3, nullable: false),
                    DurationSeconds = table.Column<int>(type: "int", nullable: false),
                    PaceMinPerKm = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: true),
                    CaloriesBurned = table.Column<int>(type: "int", nullable: false),
                    ActivityDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    TrackingMode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false, defaultValue: "MANUAL")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RunningActivities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RunningActivities_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RunningActivities_UserId",
                table: "RunningActivities",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_RunningActivities_ActivityDate",
                table: "RunningActivities",
                column: "ActivityDate");

            migrationBuilder.CreateIndex(
                name: "IX_RunningActivities_UserId_ActivityDate",
                table: "RunningActivities",
                columns: new[] { "UserId", "ActivityDate" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RunningActivities");
        }
    }
}
