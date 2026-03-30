using LifeLevel.Modules.Items.Application.DTOs;
using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/items")]
[Authorize]
public class ItemsController(ItemService itemService, IUserContext userContext) : ControllerBase
{
    [HttpGet("equipment")]
    public async Task<IActionResult> GetEquipment()
    {
        var userId = userContext.UserId;
        var equipment = await itemService.GetCharacterEquipmentAsync(userId);
        return Ok(equipment);
    }

    [HttpPost("equipment/equip")]
    public async Task<IActionResult> EquipItem([FromBody] EquipItemRequest req)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await itemService.EquipItemAsync(userId, req);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpDelete("equipment/{slotType}")]
    public async Task<IActionResult> Unequip(EquipmentSlotType slotType)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await itemService.UnequipAsync(userId, slotType);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("inventory")]
    public async Task<IActionResult> GetInventory()
    {
        var userId = userContext.UserId;
        var inventory = await itemService.GetCharacterInventoryAsync(userId);
        return Ok(inventory);
    }
}
