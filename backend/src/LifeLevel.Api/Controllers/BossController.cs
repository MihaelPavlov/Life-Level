using System.Security.Claims;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BossController(BossService bossService) : ControllerBase
{
    // ── Fight lifecycle ────────────────────────────────────────────────────────

    /// <summary>
    /// Activate the fight. Player must be at the boss node.
    /// Creates UserBossState with StartedAt = now.
    /// </summary>
    [HttpPost("{bossId:guid}/activate")]
    public async Task<IActionResult> Activate(Guid bossId)
    {
        var userId = GetUserId();
        try
        {
            var state = await bossService.ActivateFightAsync(userId, bossId);
            return Ok(new
            {
                message = "Fight activated.",
                startedAt = state.StartedAt
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deal explicit damage to the boss. Player must be at the boss node.
    /// </summary>
    [HttpPost("{bossId:guid}/damage")]
    public async Task<IActionResult> DealDamage(Guid bossId, [FromBody] DealDamageRequest request)
    {
        var userId = GetUserId();
        try
        {
            var result = await bossService.DealDamageAsync(userId, bossId, request.Damage);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deal damage calculated from activity parameters.
    /// Formula: (durationMinutes * 2 + distanceKm * 10 + calories / 5) * activityMultiplier
    /// Player must be at the boss node.
    /// </summary>
    [HttpPost("{bossId:guid}/damage/activity")]
    public async Task<IActionResult> DealActivityDamage(Guid bossId, [FromBody] ActivityDamageRequest request)
    {
        var userId = GetUserId();
        try
        {
            var damage = BossService.CalculateDamageFromActivity(
                request.ActivityType,
                request.DurationMinutes,
                request.DistanceKm,
                request.Calories);

            var result = await bossService.DealDamageAsync(userId, bossId, damage);
            return Ok(new
            {
                calculatedDamage = damage,
                result.HpDealt,
                result.MaxHp,
                result.IsDefeated,
                result.JustDefeated,
                result.RewardXpAwarded
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Get current boss fight state for the authenticated user.</summary>
    [HttpGet("{bossId:guid}/state")]
    public async Task<IActionResult> GetState(Guid bossId)
    {
        var userId = GetUserId();
        var state = await bossService.GetStateAsync(userId, bossId);

        if (state == null)
            return Ok(new { activated = false });

        return Ok(new
        {
            activated = true,
            hpDealt = state.HpDealt,
            maxHp = state.Boss.MaxHp,
            isDefeated = state.IsDefeated,
            isExpired = state.IsExpired,
            startedAt = state.StartedAt,
            timerExpiresAt = state.StartedAt?.AddDays(state.Boss.TimerDays),
            defeatedAt = state.DefeatedAt
        });
    }

    // ── Debug endpoints ────────────────────────────────────────────────────────

    /// <summary>Debug: set HpDealt directly. No zone check.</summary>
    [HttpPost("{bossId:guid}/debug/set-hp")]
    public async Task<IActionResult> DebugSetHp(Guid bossId, [FromBody] DebugSetHpRequest request)
    {
        var userId = GetUserId();
        try
        {
            await bossService.DebugSetHpAsync(userId, bossId, request.Hp);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: immediately defeat the boss and award XP.</summary>
    [HttpPost("{bossId:guid}/debug/force-defeat")]
    public async Task<IActionResult> DebugForceDefeat(Guid bossId)
    {
        var userId = GetUserId();
        try
        {
            await bossService.DebugForceDefeatAsync(userId, bossId);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: force the fight timer to expire.</summary>
    [HttpPost("{bossId:guid}/debug/force-expire")]
    public async Task<IActionResult> DebugForceExpire(Guid bossId)
    {
        var userId = GetUserId();
        try
        {
            await bossService.DebugForceExpireAsync(userId, bossId);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: reset boss state so the fight can be re-activated.</summary>
    [HttpPost("{bossId:guid}/debug/reset")]
    public async Task<IActionResult> DebugReset(Guid bossId)
    {
        var userId = GetUserId();
        await bossService.DebugResetAsync(userId, bossId);
        return NoContent();
    }

    private Guid GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(claim);
    }
}

public record DealDamageRequest(int Damage);
public record ActivityDamageRequest(string ActivityType, int DurationMinutes, double DistanceKm, int Calories);
public record DebugSetHpRequest(int Hp);
