using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace e_learning_server.SKVI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RestructureCourseManagement : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Clear data to prevent FK conflicts during restructuring
            migrationBuilder.Sql("DELETE FROM [LessonProgresses]");
            migrationBuilder.Sql("DELETE FROM [CourseLessons]");
            migrationBuilder.Sql("DELETE FROM [CourseSections]");
            migrationBuilder.DropForeignKey(
                name: "FK_CourseLessons_CourseSections_SectionId",
                table: "CourseLessons");

            migrationBuilder.DropForeignKey(
                name: "FK_CourseLessons_Videos_VideoId",
                table: "CourseLessons");

            migrationBuilder.DropForeignKey(
                name: "FK_LessonProgresses_CourseLessons_CourseLessonId",
                table: "LessonProgresses");

            migrationBuilder.DropTable(
                name: "CourseSections");

            migrationBuilder.DropIndex(
                name: "IX_LessonProgresses_CourseLessonId",
                table: "LessonProgresses");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CourseLessons",
                table: "CourseLessons");

            migrationBuilder.DropColumn(
                name: "CourseLessonId",
                table: "LessonProgresses");

            migrationBuilder.DropColumn(
                name: "Duration",
                table: "CourseLessons");

            migrationBuilder.DropColumn(
                name: "IsPreview",
                table: "CourseLessons");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "CourseLessons");

            migrationBuilder.RenameColumn(
                name: "LessonId",
                table: "LessonProgresses",
                newName: "LessonPartId");

            migrationBuilder.RenameIndex(
                name: "IX_LessonProgresses_EnrollmentId_LessonId",
                table: "LessonProgresses",
                newName: "IX_LessonProgresses_EnrollmentId_LessonPartId");

            migrationBuilder.RenameColumn(
                name: "SectionId",
                table: "CourseLessons",
                newName: "LessonId");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "CourseLessons",
                newName: "CourseId");

            migrationBuilder.RenameIndex(
                name: "IX_CourseLessons_SectionId",
                table: "CourseLessons",
                newName: "IX_CourseLessons_LessonId");

            migrationBuilder.AlterColumn<Guid>(
                name: "VideoId",
                table: "CourseLessons",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddPrimaryKey(
                name: "PK_CourseLessons",
                table: "CourseLessons",
                columns: new[] { "CourseId", "LessonId" });

            migrationBuilder.CreateTable(
                name: "Lessons",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ThumbnailUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Lessons", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LessonParts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    OrderIndex = table.Column<int>(type: "int", nullable: false),
                    IsPreview = table.Column<bool>(type: "bit", nullable: false),
                    VideoId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    DocumentId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonParts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonParts_Documents_DocumentId",
                        column: x => x.DocumentId,
                        principalTable: "Documents",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_LessonParts_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LessonParts_Videos_VideoId",
                        column: x => x.VideoId,
                        principalTable: "Videos",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_LessonPartId",
                table: "LessonProgresses",
                column: "LessonPartId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonParts_DocumentId",
                table: "LessonParts",
                column: "DocumentId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonParts_LessonId",
                table: "LessonParts",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonParts_VideoId",
                table: "LessonParts",
                column: "VideoId");

            migrationBuilder.AddForeignKey(
                name: "FK_CourseLessons_Courses_CourseId",
                table: "CourseLessons",
                column: "CourseId",
                principalTable: "Courses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CourseLessons_Lessons_LessonId",
                table: "CourseLessons",
                column: "LessonId",
                principalTable: "Lessons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CourseLessons_Videos_VideoId",
                table: "CourseLessons",
                column: "VideoId",
                principalTable: "Videos",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_LessonProgresses_LessonParts_LessonPartId",
                table: "LessonProgresses",
                column: "LessonPartId",
                principalTable: "LessonParts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CourseLessons_Courses_CourseId",
                table: "CourseLessons");

            migrationBuilder.DropForeignKey(
                name: "FK_CourseLessons_Lessons_LessonId",
                table: "CourseLessons");

            migrationBuilder.DropForeignKey(
                name: "FK_CourseLessons_Videos_VideoId",
                table: "CourseLessons");

            migrationBuilder.DropForeignKey(
                name: "FK_LessonProgresses_LessonParts_LessonPartId",
                table: "LessonProgresses");

            migrationBuilder.DropTable(
                name: "LessonParts");

            migrationBuilder.DropTable(
                name: "Lessons");

            migrationBuilder.DropIndex(
                name: "IX_LessonProgresses_LessonPartId",
                table: "LessonProgresses");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CourseLessons",
                table: "CourseLessons");

            migrationBuilder.RenameColumn(
                name: "LessonPartId",
                table: "LessonProgresses",
                newName: "LessonId");

            migrationBuilder.RenameIndex(
                name: "IX_LessonProgresses_EnrollmentId_LessonPartId",
                table: "LessonProgresses",
                newName: "IX_LessonProgresses_EnrollmentId_LessonId");

            migrationBuilder.RenameColumn(
                name: "LessonId",
                table: "CourseLessons",
                newName: "SectionId");

            migrationBuilder.RenameColumn(
                name: "CourseId",
                table: "CourseLessons",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_CourseLessons_LessonId",
                table: "CourseLessons",
                newName: "IX_CourseLessons_SectionId");

            migrationBuilder.AddColumn<Guid>(
                name: "CourseLessonId",
                table: "LessonProgresses",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "VideoId",
                table: "CourseLessons",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Duration",
                table: "CourseLessons",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsPreview",
                table: "CourseLessons",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "CourseLessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddPrimaryKey(
                name: "PK_CourseLessons",
                table: "CourseLessons",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "CourseSections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CourseId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OrderIndex = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourseSections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CourseSections_Courses_CourseId",
                        column: x => x.CourseId,
                        principalTable: "Courses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_CourseLessonId",
                table: "LessonProgresses",
                column: "CourseLessonId");

            migrationBuilder.CreateIndex(
                name: "IX_CourseSections_CourseId",
                table: "CourseSections",
                column: "CourseId");

            migrationBuilder.AddForeignKey(
                name: "FK_CourseLessons_CourseSections_SectionId",
                table: "CourseLessons",
                column: "SectionId",
                principalTable: "CourseSections",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CourseLessons_Videos_VideoId",
                table: "CourseLessons",
                column: "VideoId",
                principalTable: "Videos",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_LessonProgresses_CourseLessons_CourseLessonId",
                table: "LessonProgresses",
                column: "CourseLessonId",
                principalTable: "CourseLessons",
                principalColumn: "Id");
        }
    }
}
