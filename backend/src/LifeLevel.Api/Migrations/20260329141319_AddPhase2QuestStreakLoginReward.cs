using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPhase2QuestStreakLoginReward : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LoginRewards",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DayInCycle = table.Column<int>(type: "integer", nullable: false),
                    LastClaimedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ClaimedToday = table.Column<bool>(type: "boolean", nullable: false),
                    TotalLoginDays = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LoginRewards", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LoginRewards_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Quests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    RequiredActivity = table.Column<string>(type: "text", nullable: true),
                    TargetValue = table.Column<decimal>(type: "numeric", nullable: true),
                    TargetUnit = table.Column<string>(type: "text", nullable: false),
                    RewardXp = table.Column<int>(type: "integer", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Quests", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Streaks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Current = table.Column<int>(type: "integer", nullable: false),
                    Longest = table.Column<int>(type: "integer", nullable: false),
                    LastActivityDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ShieldsAvailable = table.Column<int>(type: "integer", nullable: false),
                    ShieldsUsed = table.Column<int>(type: "integer", nullable: false),
                    ShieldUsedToday = table.Column<bool>(type: "boolean", nullable: false),
                    TotalDaysActive = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Streaks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Streaks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserQuestProgress",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    QuestId = table.Column<Guid>(type: "uuid", nullable: false),
                    CurrentValue = table.Column<decimal>(type: "numeric", nullable: false),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    RewardClaimed = table.Column<bool>(type: "boolean", nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    BonusAwarded = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserQuestProgress", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserQuestProgress_Quests_QuestId",
                        column: x => x.QuestId,
                        principalTable: "Quests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserQuestProgress_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Quests",
                columns: new[] { "Id", "Category", "Description", "IsActive", "RequiredActivity", "RewardXp", "SortOrder", "TargetUnit", "TargetValue", "Title", "Type" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-0001-0000-0000-000000000000"), "Duration", "Complete any workout lasting at least 30 minutes.", true, null, 150, 1, "minutes", 30m, "Morning Mover", "Daily" },
                    { new Guid("bbbbbbbb-0002-0000-0000-000000000000"), "Calories", "Burn at least 300 calories in a single session.", true, null, 200, 2, "calories", 300m, "Calorie Crusher", "Daily" },
                    { new Guid("bbbbbbbb-0003-0000-0000-000000000000"), "Distance", "Run at least 5 km.", true, "Running", 250, 3, "km", 5m, "Road Warrior", "Daily" },
                    { new Guid("bbbbbbbb-0004-0000-0000-000000000000"), "Duration", "Hit the gym for at least 45 minutes.", true, "Gym", 200, 4, "minutes", 45m, "Iron Session", "Daily" },
                    { new Guid("bbbbbbbb-0005-0000-0000-000000000000"), "Duration", "Practice yoga for at least 30 minutes.", true, "Yoga", 150, 5, "minutes", 30m, "Zen Master", "Daily" },
                    { new Guid("bbbbbbbb-0006-0000-0000-000000000000"), "Duration", "Run for at least 30 minutes.", true, "Running", 175, 6, "minutes", 30m, "Endurance Push", "Daily" },
                    { new Guid("bbbbbbbb-0007-0000-0000-000000000000"), "Workouts", "Complete 3 workouts this week.", true, null, 500, 1, "workouts", 3m, "Triple Threat", "Weekly" },
                    { new Guid("bbbbbbbb-0008-0000-0000-000000000000"), "Distance", "Run a total of 10 km this week.", true, "Running", 600, 2, "km", 10m, "Road Runner", "Weekly" },
                    { new Guid("bbbbbbbb-0009-0000-0000-000000000000"), "Duration", "Spend at least 90 minutes at the gym this week.", true, "Gym", 550, 3, "minutes", 90m, "Iron Week", "Weekly" },
                    { new Guid("bbbbbbbb-0010-0000-0000-000000000000"), "Distance", "Run a total of 10 km across all activities.", true, "Running", 1000, 1, "km", 10m, "First Steps", "Special" },
                    { new Guid("bbbbbbbb-0011-0000-0000-000000000000"), "Duration", "Spend 60 minutes climbing.", true, "Climbing", 1200, 2, "minutes", 60m, "Summit Seeker", "Special" },
                    { new Guid("bbbbbbbb-0012-0000-0000-000000000000"), "Duration", "Log a total of 500 minutes of any activity.", true, null, 2000, 3, "minutes", 500m, "Endurance Initiate", "Special" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_LoginRewards_UserId",
                table: "LoginRewards",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Streaks_UserId",
                table: "Streaks",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserQuestProgress_QuestId",
                table: "UserQuestProgress",
                column: "QuestId");

            migrationBuilder.CreateIndex(
                name: "IX_UserQuestProgress_UserId",
                table: "UserQuestProgress",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LoginRewards");

            migrationBuilder.DropTable(
                name: "Streaks");

            migrationBuilder.DropTable(
                name: "UserQuestProgress");

            migrationBuilder.DropTable(
                name: "Quests");
        }
    }
}
