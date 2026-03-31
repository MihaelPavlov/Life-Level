using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/items")]
[Authorize(Policy = "Admin")]
public class AdminItemsController(AppDbContext db, ItemGrantService grantService) : ControllerBase
{
    // GET /api/admin/items
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var items = await db.Items
            .Select(i => new
            {
                i.Id, i.Name, i.Description, i.Icon,
                Rarity = i.Rarity.ToString(),
                Category = i.Category.ToString(),
                SlotType = i.SlotType.ToString(),
                i.XpBonusPct, i.StrBonus, i.EndBonus, i.AgiBonus, i.FlxBonus, i.StaBonus
            })
            .ToListAsync();
        return Ok(items);
    }

    // POST /api/admin/items
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UpsertItemRequest req)
    {
        var item = new Item
        {
            Id = Guid.NewGuid(),
            Name = req.Name, Description = req.Description, Icon = req.Icon,
            Rarity = Enum.Parse<ItemRarity>(req.Rarity),
            Category = Enum.Parse<ItemCategory>(req.Category),
            SlotType = Enum.Parse<EquipmentSlotType>(req.SlotType),
            XpBonusPct = req.XpBonusPct, StrBonus = req.StrBonus, EndBonus = req.EndBonus,
            AgiBonus = req.AgiBonus, FlxBonus = req.FlxBonus, StaBonus = req.StaBonus
        };
        db.Items.Add(item);
        await db.SaveChangesAsync();
        return Ok(new { item.Id });
    }

    // PUT /api/admin/items/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpsertItemRequest req)
    {
        var item = await db.Items.FindAsync(id);
        if (item == null) return NotFound();
        item.Name = req.Name; item.Description = req.Description; item.Icon = req.Icon;
        item.Rarity = Enum.Parse<ItemRarity>(req.Rarity);
        item.Category = Enum.Parse<ItemCategory>(req.Category);
        item.SlotType = Enum.Parse<EquipmentSlotType>(req.SlotType);
        item.XpBonusPct = req.XpBonusPct; item.StrBonus = req.StrBonus; item.EndBonus = req.EndBonus;
        item.AgiBonus = req.AgiBonus; item.FlxBonus = req.FlxBonus; item.StaBonus = req.StaBonus;
        await db.SaveChangesAsync();
        return Ok();
    }

    // DELETE /api/admin/items/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var item = await db.Items.FindAsync(id);
        if (item == null) return NotFound();
        db.Items.Remove(item);
        await db.SaveChangesAsync();
        return Ok();
    }

    // GET /api/admin/items/{id}/drop-rules
    [HttpGet("{id:guid}/drop-rules")]
    public async Task<IActionResult> GetDropRules(Guid id)
    {
        var rules = await db.ItemDropRules
            .Where(r => r.ItemId == id)
            .Select(r => new { r.Id, TriggerType = r.TriggerType.ToString(), r.TriggerParameters, r.DropChancePct, r.IsEnabled })
            .ToListAsync();
        return Ok(rules);
    }

    // POST /api/admin/items/{id}/drop-rules
    [HttpPost("{id:guid}/drop-rules")]
    public async Task<IActionResult> AddDropRule(Guid id, [FromBody] UpsertDropRuleRequest req)
    {
        if (!await db.Items.AnyAsync(i => i.Id == id)) return NotFound();
        var rule = new ItemDropRule
        {
            Id = Guid.NewGuid(), ItemId = id,
            TriggerType = Enum.Parse<AcquisitionTrigger>(req.TriggerType),
            TriggerParameters = req.TriggerParameters,
            DropChancePct = req.DropChancePct,
            IsEnabled = req.IsEnabled
        };
        db.ItemDropRules.Add(rule);
        await db.SaveChangesAsync();
        return Ok(new { rule.Id });
    }

    // PUT /api/admin/items/drop-rules/{ruleId}
    [HttpPut("drop-rules/{ruleId:guid}")]
    public async Task<IActionResult> UpdateDropRule(Guid ruleId, [FromBody] UpsertDropRuleRequest req)
    {
        var rule = await db.ItemDropRules.FindAsync(ruleId);
        if (rule == null) return NotFound();
        rule.TriggerType = Enum.Parse<AcquisitionTrigger>(req.TriggerType);
        rule.TriggerParameters = req.TriggerParameters;
        rule.DropChancePct = req.DropChancePct;
        rule.IsEnabled = req.IsEnabled;
        await db.SaveChangesAsync();
        return Ok();
    }

    // DELETE /api/admin/items/drop-rules/{ruleId}
    [HttpDelete("drop-rules/{ruleId:guid}")]
    public async Task<IActionResult> DeleteDropRule(Guid ruleId)
    {
        var rule = await db.ItemDropRules.FindAsync(ruleId);
        if (rule == null) return NotFound();
        db.ItemDropRules.Remove(rule);
        await db.SaveChangesAsync();
        return Ok();
    }

    // POST /api/admin/items/grant
    [HttpPost("grant")]
    public async Task<IActionResult> GrantItem([FromBody] GrantItemRequest req)
    {
        var result = await grantService.GrantItemAsync(req.UserId, req.ItemId);
        if (result == null) return BadRequest("User or item not found.");
        return Ok(new { result.Id, result.ItemId, result.CharacterId });
    }
}

public record UpsertItemRequest(string Name, string Description, string Icon,
    string Rarity, string Category, string SlotType,
    int XpBonusPct, int StrBonus, int EndBonus, int AgiBonus, int FlxBonus, int StaBonus);

public record UpsertDropRuleRequest(string TriggerType, string TriggerParameters, int DropChancePct, bool IsEnabled);

public record GrantItemRequest(Guid UserId, Guid ItemId);
