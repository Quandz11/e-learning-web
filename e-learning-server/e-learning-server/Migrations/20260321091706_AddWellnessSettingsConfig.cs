using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddWellnessSettingsConfig : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WellnessSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Trial3DayCourseIdsCsv = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    Plan30DayCourseIdsCsv = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    CtaPath = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WellnessSettings", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WellnessSettings_UpdatedAt",
                table: "WellnessSettings",
                column: "UpdatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WellnessSettings");
        }
    }
}
