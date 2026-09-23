using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTaskRewardCenter : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RewardCoins",
                table: "UserQuestProgress",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RewardCrystals",
                table: "UserQuestProgress",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RewardPoints",
                table: "UserQuestProgress",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "TaskRewardMilestoneClaims",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PeriodType = table.Column<string>(type: "text", nullable: false),
                    PeriodStartUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Threshold = table.Column<int>(type: "integer", nullable: false),
                    ClaimedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskRewardMilestoneClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TaskRewardMilestoneClaims_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0L);

            migrationBuilder.InsertData(
                table: "Quests",
                columns: new[] { "Id", "Category", "Description", "IsActive", "RequiredActivity", "RewardXp", "SortOrder", "TargetUnit", "TargetValue", "Title", "Type" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-0101-0000-0000-000000000000"), "Workouts", "Complete one workout.", true, null, 0L, 7, "workout", 1.0, "First Move", "Daily" },
                    { new Guid("bbbbbbbb-0102-0000-0000-000000000000"), "Workouts", "Complete two workouts.", true, null, 0L, 8, "workouts", 2.0, "Double Move", "Daily" },
                    { new Guid("bbbbbbbb-0103-0000-0000-000000000000"), "Duration", "Stay active for 10 minutes.", true, null, 0L, 9, "minutes", 10.0, "Quick Start", "Daily" },
                    { new Guid("bbbbbbbb-0104-0000-0000-000000000000"), "Duration", "Stay active for 60 minutes.", true, null, 0L, 10, "minutes", 60.0, "Power Hour", "Daily" },
                    { new Guid("bbbbbbbb-0105-0000-0000-000000000000"), "Calories", "Burn 100 calories.", true, null, 0L, 11, "calories", 100.0, "First Burn", "Daily" },
                    { new Guid("bbbbbbbb-0106-0000-0000-000000000000"), "Distance", "Cover 1 km.", true, null, 0L, 12, "km", 1.0, "First Kilometer", "Daily" },
                    { new Guid("bbbbbbbb-0107-0000-0000-000000000000"), "Distance", "Cover 3 km.", true, null, 0L, 13, "km", 3.0, "Distance Day", "Daily" },
                    { new Guid("bbbbbbbb-0108-0000-0000-000000000000"), "Distance", "Cycle 5 km.", true, "Cycling", 0L, 14, "km", 5.0, "Cycle Circuit", "Daily" },
                    { new Guid("bbbbbbbb-0109-0000-0000-000000000000"), "Duration", "Swim for 20 minutes.", true, "Swimming", 0L, 15, "minutes", 20.0, "Pool Time", "Daily" },
                    { new Guid("bbbbbbbb-0201-0000-0000-000000000000"), "Workouts", "Complete 5 workouts this week.", true, null, 0L, 4, "workouts", 5.0, "Five Strong", "Weekly" },
                    { new Guid("bbbbbbbb-0202-0000-0000-000000000000"), "Workouts", "Complete 7 workouts this week.", true, null, 0L, 5, "workouts", 7.0, "Perfect Week", "Weekly" },
                    { new Guid("bbbbbbbb-0203-0000-0000-000000000000"), "Duration", "Log 90 active minutes this week.", true, null, 0L, 6, "minutes", 90.0, "Active Ninety", "Weekly" },
                    { new Guid("bbbbbbbb-0204-0000-0000-000000000000"), "Duration", "Log 180 active minutes this week.", true, null, 0L, 7, "minutes", 180.0, "Three Hour Hero", "Weekly" },
                    { new Guid("bbbbbbbb-0205-0000-0000-000000000000"), "Duration", "Log 300 active minutes this week.", true, null, 0L, 8, "minutes", 300.0, "Five Hour Force", "Weekly" },
                    { new Guid("bbbbbbbb-0206-0000-0000-000000000000"), "Calories", "Burn 500 calories this week.", true, null, 0L, 9, "calories", 500.0, "Kindle the Flame", "Weekly" },
                    { new Guid("bbbbbbbb-0207-0000-0000-000000000000"), "Calories", "Burn 1,000 calories this week.", true, null, 0L, 10, "calories", 1000.0, "Blazing Week", "Weekly" },
                    { new Guid("bbbbbbbb-0208-0000-0000-000000000000"), "Calories", "Burn 2,000 calories this week.", true, null, 0L, 11, "calories", 2000.0, "Inferno Week", "Weekly" },
                    { new Guid("bbbbbbbb-0209-0000-0000-000000000000"), "Distance", "Cover 5 km this week.", true, null, 0L, 12, "km", 5.0, "First Five", "Weekly" },
                    { new Guid("bbbbbbbb-0210-0000-0000-000000000000"), "Distance", "Cover 15 km this week.", true, null, 0L, 13, "km", 15.0, "Distance Fifteen", "Weekly" },
                    { new Guid("bbbbbbbb-0211-0000-0000-000000000000"), "Distance", "Cover 30 km this week.", true, null, 0L, 14, "km", 30.0, "Long Haul", "Weekly" },
                    { new Guid("bbbbbbbb-0212-0000-0000-000000000000"), "Duration", "Practice yoga for 60 minutes this week.", true, "Yoga", 0L, 15, "minutes", 60.0, "Yoga Week", "Weekly" },
                    { new Guid("bbbbbbbb-0213-0000-0000-000000000000"), "Distance", "Cycle 25 km this week.", true, "Cycling", 0L, 16, "km", 25.0, "Cycle Week", "Weekly" },
                    { new Guid("bbbbbbbb-0214-0000-0000-000000000000"), "Duration", "Swim for 60 minutes this week.", true, "Swimming", 0L, 17, "minutes", 60.0, "Swim Week", "Weekly" },
                    { new Guid("bbbbbbbb-0215-0000-0000-000000000000"), "Duration", "Climb for 60 minutes this week.", true, "Climbing", 0L, 18, "minutes", 60.0, "Climb Week", "Weekly" },
                    { new Guid("bbbbbbbb-0216-0000-0000-000000000000"), "Distance", "Hike 10 km this week.", true, "Hiking", 0L, 19, "km", 10.0, "Hike Week", "Weekly" },
                    { new Guid("bbbbbbbb-0217-0000-0000-000000000000"), "Distance", "Walk 20 km this week.", true, "Walking", 0L, 20, "km", 20.0, "Walk Week", "Weekly" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_TaskRewardMilestoneClaims_UserId_PeriodType_PeriodStartUtc_~",
                table: "TaskRewardMilestoneClaims",
                columns: new[] { "UserId", "PeriodType", "PeriodStartUtc", "Threshold" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TaskRewardMilestoneClaims");

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0101-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0102-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0103-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0104-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0105-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0106-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0107-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0108-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0109-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0201-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0202-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0203-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0204-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0205-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0206-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0207-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0208-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0209-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0210-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0211-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0212-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0213-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0214-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0215-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0216-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0217-0000-0000-000000000000"));

            migrationBuilder.DropColumn(
                name: "RewardCoins",
                table: "UserQuestProgress");

            migrationBuilder.DropColumn(
                name: "RewardCrystals",
                table: "UserQuestProgress");

            migrationBuilder.DropColumn(
                name: "RewardPoints",
                table: "UserQuestProgress");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"),
                column: "RewardXp",
                value: 150L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"),
                column: "RewardXp",
                value: 200L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"),
                column: "RewardXp",
                value: 250L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"),
                column: "RewardXp",
                value: 200L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"),
                column: "RewardXp",
                value: 150L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"),
                column: "RewardXp",
                value: 175L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"),
                column: "RewardXp",
                value: 500L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"),
                column: "RewardXp",
                value: 600L);

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"),
                column: "RewardXp",
                value: 550L);
        }
    }
}
