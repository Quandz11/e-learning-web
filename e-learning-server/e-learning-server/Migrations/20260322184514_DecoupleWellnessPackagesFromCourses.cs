using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class DecoupleWellnessPackagesFromCourses : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Plan30DayCourseIdsCsv",
                table: "WellnessSettings");

            migrationBuilder.DropColumn(
                name: "Trial3DayCourseIdsCsv",
                table: "WellnessSettings");

            migrationBuilder.CreateTable(
                name: "WellnessPackages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Code = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    PriceVnd = table.Column<decimal>(type: "decimal(18,0)", nullable: false),
                    DurationDays = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    IsFeatured = table.Column<bool>(type: "bit", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessPackages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WellnessUserPackages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PackageId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    Source = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    GrantedByUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(1024)", maxLength: 1024, nullable: false),
                    GrantedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    StartsAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessUserPackages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WellnessUserPackages_Users_GrantedByUserId",
                        column: x => x.GrantedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WellnessUserPackages_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WellnessUserPackages_WellnessPackages_PackageId",
                        column: x => x.PackageId,
                        principalTable: "WellnessPackages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessPackages_Code",
                table: "WellnessPackages",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WellnessPackages_IsActive_SortOrder",
                table: "WellnessPackages",
                columns: new[] { "IsActive", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessUserPackages_GrantedByUserId",
                table: "WellnessUserPackages",
                column: "GrantedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessUserPackages_PackageId",
                table: "WellnessUserPackages",
                column: "PackageId");

            migrationBuilder.CreateIndex(
                name: "IX_WellnessUserPackages_UserId_Status_ExpiresAt",
                table: "WellnessUserPackages",
                columns: new[] { "UserId", "Status", "ExpiresAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WellnessUserPackages");

            migrationBuilder.DropTable(
                name: "WellnessPackages");

            migrationBuilder.AddColumn<string>(
                name: "Plan30DayCourseIdsCsv",
                table: "WellnessSettings",
                type: "nvarchar(4000)",
                maxLength: 4000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Trial3DayCourseIdsCsv",
                table: "WellnessSettings",
                type: "nvarchar(4000)",
                maxLength: 4000,
                nullable: false,
                defaultValue: "");
        }
    }
}
