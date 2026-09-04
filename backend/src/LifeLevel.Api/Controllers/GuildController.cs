using LifeLevel.Modules.Guild.Application.DTOs;
using LifeLevel.Modules.Guild.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/guild")]
[Authorize]
public class GuildController(GuildService guildService, IUserContext userContext) : ControllerBase
{
    [HttpGet("mine")]
    public async Task<ActionResult<GuildDetailDto?>> Mine(CancellationToken ct)
    {
        return Ok(await guildService.GetMineAsync(userContext.UserId, ct));
    }

    [HttpPost]
    public async Task<ActionResult<GuildDetailDto>> Create([FromBody] GuildCreateRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await guildService.CreateAsync(userContext.UserId, request, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut]
    public async Task<ActionResult<GuildDetailDto>> Update([FromBody] GuildUpdateRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await guildService.UpdateAsync(userContext.UserId, request, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("search")]
    public async Task<ActionResult<IReadOnlyList<GuildSearchItemDto>>> Search(
        [FromQuery] string? q,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 20,
        CancellationToken ct = default)
    {
        return Ok(await guildService.SearchAsync(q, skip, take, ct));
    }

    [HttpPost("{guildId:guid}/join")]
    public async Task<ActionResult<GuildDetailDto>> Join(Guid guildId, CancellationToken ct)
    {
        try
        {
            return Ok(await guildService.JoinAsync(userContext.UserId, guildId, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("leave")]
    public async Task<IActionResult> Leave(CancellationToken ct)
    {
        try
        {
            await guildService.LeaveAsync(userContext.UserId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete]
    public async Task<IActionResult> Delete(CancellationToken ct)
    {
        try
        {
            await guildService.DeleteAsync(userContext.UserId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{guildId:guid}/kick/{targetUserId:guid}")]
    public async Task<IActionResult> Kick(Guid guildId, Guid targetUserId, CancellationToken ct)
    {
        try
        {
            await guildService.KickAsync(userContext.UserId, guildId, targetUserId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{guildId:guid}/members/{targetUserId:guid}/role")]
    public async Task<ActionResult<GuildDetailDto>> UpdateMemberRole(
        Guid guildId,
        Guid targetUserId,
        [FromBody] GuildRoleUpdateRequest request,
        CancellationToken ct)
    {
        try
        {
            return Ok(await guildService.UpdateMemberRoleAsync(userContext.UserId, guildId, targetUserId, request, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("raid/bosses")]
    public async Task<ActionResult<IReadOnlyList<GuildRaidBossDto>>> RaidBosses(CancellationToken ct)
    {
        return Ok(await guildService.GetRaidBossesAsync(ct));
    }

    [HttpPost("raid/start")]
    public async Task<ActionResult<GuildRaidDto>> StartRaid([FromBody] GuildStartRaidRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await guildService.StartRaidAsync(userContext.UserId, request.BossId, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("raid")]
    public async Task<ActionResult<GuildRaidDto?>> ActiveRaid(CancellationToken ct)
    {
        return Ok(await guildService.GetActiveRaidAsync(userContext.UserId, ct));
    }

    [HttpGet("raid/history")]
    public async Task<ActionResult<IReadOnlyList<GuildRaidDto>>> RaidHistory(CancellationToken ct)
    {
        return Ok(await guildService.GetRaidHistoryAsync(userContext.UserId, ct));
    }

    [HttpGet("raid/victories/pending")]
    public async Task<ActionResult<IReadOnlyList<GuildRaidDefeatedInfo>>> PendingRaidVictories(CancellationToken ct)
    {
        return Ok(await guildService.GetPendingVictoryAcknowledgementsAsync(userContext.UserId, ct));
    }

    [HttpPost("raid/victories/ack")]
    public async Task<IActionResult> AcknowledgeRaidVictory([FromBody] GuildRaidVictoryAckRequest request, CancellationToken ct)
    {
        try
        {
            await guildService.AcknowledgeVictoryAsync(userContext.UserId, request.GuildRaidId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("raid/expiries/pending")]
    public async Task<ActionResult<IReadOnlyList<GuildRaidExpiredInfo>>> PendingRaidExpiries(CancellationToken ct)
    {
        return Ok(await guildService.GetPendingExpiryAcknowledgementsAsync(userContext.UserId, ct));
    }

    [HttpPost("raid/expiries/ack")]
    public async Task<IActionResult> AcknowledgeRaidExpiry([FromBody] GuildRaidExpiryAckRequest request, CancellationToken ct)
    {
        try
        {
            await guildService.AcknowledgeExpiryAsync(userContext.UserId, request.GuildRaidId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("raid/debug/add-damage")]
    public async Task<IActionResult> DebugAddDamage([FromBody] GuildDebugDamageRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await guildService.DebugAddDamageAsync(userContext.UserId, request.Damage, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("raid/debug/force-expire")]
    public async Task<IActionResult> DebugForceExpire(CancellationToken ct)
    {
        try
        {
            await guildService.ForceExpireAsync(userContext.UserId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
