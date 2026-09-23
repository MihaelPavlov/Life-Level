using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddShopPurchases : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_CharacterItems_CharacterId",
                table: "CharacterItems");

            migrationBuilder.CreateTable(
                name: "ShopPurchases",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientPurchaseId = table.Column<Guid>(type: "uuid", nullable: false),
                    OfferKey = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    GrantedItemId = table.Column<Guid>(type: "uuid", nullable: false),
                    Currency = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    Price = table.Column<int>(type: "integer", nullable: false),
                    PurchasedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShopPurchases", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ShopPurchases_Items_GrantedItemId",
                        column: x => x.GrantedItemId,
                        principalTable: "Items",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ShopPurchases_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserShopDailyStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RotationDateUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ItemIdsJson = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    RefreshedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserShopDailyStates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserShopDailyStates_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CharacterItems_CharacterId_ItemId",
                table: "CharacterItems",
                columns: new[] { "CharacterId", "ItemId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ShopPurchases_GrantedItemId",
                table: "ShopPurchases",
                column: "GrantedItemId");

            migrationBuilder.CreateIndex(
                name: "IX_ShopPurchases_UserId_ClientPurchaseId",
                table: "ShopPurchases",
                columns: new[] { "UserId", "ClientPurchaseId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserShopDailyStates_UserId_RotationDateUtc",
                table: "UserShopDailyStates",
                columns: new[] { "UserId", "RotationDateUtc" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ShopPurchases");

            migrationBuilder.DropTable(
                name: "UserShopDailyStates");

            migrationBuilder.DropIndex(
                name: "IX_CharacterItems_CharacterId_ItemId",
                table: "CharacterItems");

            migrationBuilder.CreateIndex(
                name: "IX_CharacterItems_CharacterId",
                table: "CharacterItems",
                column: "CharacterId");
        }
    }
}
