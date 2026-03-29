using LifeLevel.Api.Application;
using LifeLevel.Api.Application.DTOs.Character;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/character")]
[Authorize]
public class CharacterController(CharacterService characterService, IUserContext userContext) : ControllerBase
{
    [HttpPost("setup")]
    public async Task<IActionResult> Setup([FromBody] CharacterSetupRequest req)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await characterService.SetupAsync(userId, req);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = userContext.UserId;
        try
        {
            var result = await characterService.GetProfileAsync(userId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpGet("xp-history")]
    public async Task<IActionResult> GetXpHistory()
    {
        var userId = userContext.UserId;
        var history = await characterService.GetXpHistoryAsync(userId);
        return Ok(history);
    }

    [HttpPost("spend-stat")]
    public async Task<IActionResult> SpendStat([FromBody] SpendStatRequest req)
    {
        var userId = userContext.UserId;
        try
        {
            await characterService.SpendStatPointAsync(userId, req.Stat);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
