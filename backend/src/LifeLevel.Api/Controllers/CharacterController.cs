using LifeLevel.Api.Application;
using LifeLevel.SharedKernel.Calculators;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Ports;
using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/character")]
[Authorize]
public class CharacterController(
    CharacterService characterService,
    ClassRecommendationService classRecommendation,
    IUserContext userContext,
    IActivityStatsReadPort activityStatsPort,
    IStreakReadPort streakReadPort,
    IDailyQuestReadPort dailyQuestReadPort,
    IBossDefeatedCountReadPort bossDefeatedCountReadPort,
    IUserReadPort userReadPort,
    IGearBonusReadPort gearBonusReadPort,
    ITalentProfileReadPort talentProfileReadPort,
    ITalentBonusReadPort talentBonusReadPort) : ControllerBase
{
    [HttpPost("setup")]
    public async Task<IActionResult> Setup([FromBody] CharacterSetupRequest req)
    {
        var userId = userContext.UserId;
        try
        {
            var detection = await classRecommendation.DetectAsync(userId);
            var result = await characterService.SetupAsync(userId, req, detection);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// GET /api/character/class-recommendation — the class that fits the
    /// player's last 30 days of training, with shares for the onboarding scan.
    /// </summary>
    [HttpGet("class-recommendation")]
    public async Task<IActionResult> GetClassRecommendation(CancellationToken ct)
    {
        var result = await classRecommendation.GetAsync(userContext.UserId, ct);
        return Ok(result);
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = userContext.UserId;
        try
        {
            var ctx = new CharacterProfileContext(
                Username: await userReadPort.GetUsernameAsync(userId) ?? string.Empty,
                WeeklyStats: await activityStatsPort.GetWeeklyStatsAsync(userId),
                Streak: await streakReadPort.GetCurrentStreakAsync(userId),
                DailyQuestsCompleted: await dailyQuestReadPort.CountCompletedDailyQuestsAsync(userId),
                BossesDefeated: await bossDefeatedCountReadPort.GetDefeatedCountAsync(userId)
            );
            var profile = await characterService.GetProfileAsync(userId, ctx);
            var gearBonuses = await gearBonusReadPort.GetEquippedBonusesAsync(userId);
            var talents = await talentProfileReadPort.GetSummaryAsync(userId);
            var talentBonuses = await talentBonusReadPort.GetBonusesAsync(userId);

            var effStr = profile.Strength + gearBonuses.StrBonus + talentBonuses.StrBonus;
            var effEnd = profile.Endurance + gearBonuses.EndBonus + talentBonuses.EndBonus;
            var effAgi = profile.Agility + gearBonuses.AgiBonus + talentBonuses.AgiBonus;
            var effFlx = profile.Flexibility + gearBonuses.FlxBonus + talentBonuses.FlxBonus;
            var effSta = profile.Stamina + gearBonuses.StaBonus + talentBonuses.StaBonus;

            var attack = CombatStatsCalculator.CalculateAttack(effStr, effAgi, talentBonuses.BossDamagePct);
            var defense = CombatStatsCalculator.CalculateDefense(effAgi, effFlx);
            var health = CombatStatsCalculator.CalculateHealth(effSta, effEnd);
            var power = CombatStatsCalculator.CalculatePower(profile.Level, attack, defense, health, ctx.BossesDefeated);

            var result = profile with
            {
                GearBonuses = gearBonuses,
                Talents = talents,
                Attack = attack,
                Defense = defense,
                Health = health,
                Power = power
            };
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpGet("avatars")]
    public async Task<IActionResult> GetAvatars(CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var ctx = await BuildProfileContextAsync(userId, ct);
            return Ok(await characterService.GetAvatarsAsync(userId, ctx, ct));
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPut("avatar")]
    public async Task<IActionResult> UpdateAvatar([FromBody] UpdateAvatarRequest req, CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var ctx = await BuildProfileContextAsync(userId, ct);
            await characterService.UpdateAvatarAsync(userId, req, ctx, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("xp-history")]
    public async Task<IActionResult> GetXpHistory()
    {
        var userId = userContext.UserId;
        var history = await characterService.GetXpHistoryAsync(userId);
        return Ok(history);
    }

    [HttpGet("level-ups/pending")]
    public async Task<IActionResult> GetPendingLevelUps(CancellationToken ct)
        => Ok(await characterService.GetPendingLevelUpsAsync(userContext.UserId, ct));

    [HttpPost("level-ups/{receiptId:guid}/acknowledge")]
    public async Task<IActionResult> AcknowledgeLevelUp(Guid receiptId, CancellationToken ct)
    {
        try
        {
            await characterService.AcknowledgeLevelUpAsync(userContext.UserId, receiptId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPost("spend-stat")]
    public async Task<IActionResult> SpendStat(
        [FromBody] SpendStatRequest req,
        CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            await characterService.SpendStatPointAsync(
                userId, req.Stat, req.ExpectedAvailablePoints);
            var context = await BuildProfileContextAsync(userId, ct);
            return Ok(await characterService.GetProfileAsync(userId, context));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    private async Task<CharacterProfileContext> BuildProfileContextAsync(Guid userId, CancellationToken ct) =>
        new(
            Username: await userReadPort.GetUsernameAsync(userId) ?? string.Empty,
            WeeklyStats: await activityStatsPort.GetWeeklyStatsAsync(userId, ct),
            Streak: await streakReadPort.GetCurrentStreakAsync(userId, ct),
            DailyQuestsCompleted: await dailyQuestReadPort.CountCompletedDailyQuestsAsync(userId, ct),
            BossesDefeated: await bossDefeatedCountReadPort.GetDefeatedCountAsync(userId, ct)
        );
}
