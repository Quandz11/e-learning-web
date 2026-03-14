using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.Migrations
{
    /// <inheritdoc />
    public partial class AddPayOSCheckoutFlow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PaymentLinkId",
                table: "PaymentTransactions",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Provider",
                table: "PaymentTransactions",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Reference",
                table: "PaymentTransactions",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "WebhookProcessedAt",
                table: "PaymentTransactions",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "PaymentMethods",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<Guid>(
                name: "CabinId",
                table: "Orders",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ExpiresAt",
                table: "Orders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LastPaymentStatus",
                table: "Orders",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PayOSOrderCode",
                table: "Orders",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OrderId",
                table: "Enrollments",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SourceType",
                table: "Enrollments",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ReferralCode",
                table: "Cabins",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_PaymentTransactions_PaymentLinkId",
                table: "PaymentTransactions",
                column: "PaymentLinkId",
                unique: true,
                filter: "[PaymentLinkId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentMethods_Code",
                table: "PaymentMethods",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_CabinId",
                table: "Orders",
                column: "CabinId");

            migrationBuilder.CreateIndex(
                name: "IX_Orders_PayOSOrderCode",
                table: "Orders",
                column: "PayOSOrderCode",
                unique: true,
                filter: "[PayOSOrderCode] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Enrollments_OrderId",
                table: "Enrollments",
                column: "OrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Cabins_ReferralCode",
                table: "Cabins",
                column: "ReferralCode",
                unique: true,
                filter: "[ReferralCode] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_Enrollments_Orders_OrderId",
                table: "Enrollments",
                column: "OrderId",
                principalTable: "Orders",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Cabins_CabinId",
                table: "Orders",
                column: "CabinId",
                principalTable: "Cabins",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Enrollments_Orders_OrderId",
                table: "Enrollments");

            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Cabins_CabinId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_PaymentTransactions_PaymentLinkId",
                table: "PaymentTransactions");

            migrationBuilder.DropIndex(
                name: "IX_PaymentMethods_Code",
                table: "PaymentMethods");

            migrationBuilder.DropIndex(
                name: "IX_Orders_CabinId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_PayOSOrderCode",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Enrollments_OrderId",
                table: "Enrollments");

            migrationBuilder.DropIndex(
                name: "IX_Cabins_ReferralCode",
                table: "Cabins");

            migrationBuilder.DropColumn(
                name: "PaymentLinkId",
                table: "PaymentTransactions");

            migrationBuilder.DropColumn(
                name: "Provider",
                table: "PaymentTransactions");

            migrationBuilder.DropColumn(
                name: "Reference",
                table: "PaymentTransactions");

            migrationBuilder.DropColumn(
                name: "WebhookProcessedAt",
                table: "PaymentTransactions");

            migrationBuilder.DropColumn(
                name: "CabinId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ExpiresAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "LastPaymentStatus",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PayOSOrderCode",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "OrderId",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "SourceType",
                table: "Enrollments");

            migrationBuilder.DropColumn(
                name: "ReferralCode",
                table: "Cabins");

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "PaymentMethods",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");
        }
    }
}
