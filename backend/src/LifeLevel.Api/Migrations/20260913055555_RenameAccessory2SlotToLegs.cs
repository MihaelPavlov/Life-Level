using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class RenameAccessory2SlotToLegs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // EquipmentSlotType.Accessory2 was renamed to EquipmentSlotType.Legs.
            // SlotType is stored as text, so existing "Accessory2" rows need a
            // matching data fix. Catalog items that used to live in Accessory2
            // move to Accessory1 (the two generic accessory/consumable slots are
            // being consolidated into one); "Legs" becomes a real body slot.
            migrationBuilder.Sql(
                """UPDATE "Items" SET "SlotType" = 'Accessory1' WHERE "SlotType" = 'Accessory2';""");

            // EquipmentSlots has a unique (CharacterId, SlotType) index, so a
            // character who already has something equipped in Accessory1 can't
            // also get their Accessory2 row renamed to Accessory1 in place —
            // drop that row (unequipping it) before renaming the rest.
            migrationBuilder.Sql(
                """
                DELETE FROM "EquipmentSlots" es2
                WHERE es2."SlotType" = 'Accessory2'
                  AND EXISTS (
                      SELECT 1 FROM "EquipmentSlots" es1
                      WHERE es1."CharacterId" = es2."CharacterId" AND es1."SlotType" = 'Accessory1'
                  );
                """);

            migrationBuilder.Sql(
                """UPDATE "EquipmentSlots" SET "SlotType" = 'Accessory1' WHERE "SlotType" = 'Accessory2';""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Best-effort only: items/slots that were moved from Accessory2 to
            // Accessory1 can't be distinguished from ones that were always on
            // Accessory1, so this cannot fully reverse the Up migration.
        }
    }
}
