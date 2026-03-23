using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderWellnessPackageReference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "WellnessPackageId",
                table: "Orders",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_WellnessPackageId",
                table: "Orders",
                column: "WellnessPackageId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_WellnessPackages_WellnessPackageId",
                table: "Orders",
                column: "WellnessPackageId",
                principalTable: "WellnessPackages",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_WellnessPackages_WellnessPackageId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_WellnessPackageId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "WellnessPackageId",
                table: "Orders");
        }
    }
}
