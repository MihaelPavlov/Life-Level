using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/titles")]
[Authorize]
public class TitlesController(TitleService titleService, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetTitlesAndRanks(CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await titleService.GetTitlesAndRanksAsync(userId, ct);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPost("equip")]
    public async Task<IActionResult> EquipTitle([FromBody] EquipTitleRequest req, CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await titleService.EquipTitleAsync(userId, req.TitleId, ct);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
