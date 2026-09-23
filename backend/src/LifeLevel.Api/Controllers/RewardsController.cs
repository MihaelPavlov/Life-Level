using LifeLevel.Modules.LoginReward.Application.UseCases;
using LifeLevel.Modules.Quest.Application.UseCases;
using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/rewards")]
[Authorize]
public class RewardsController(
    QuestService tasks,
    LoginRewardService loginRewards,
    ITalentProfileReadPort talentProfile,
    IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var userId = userContext.UserId;
        var login = await loginRewards.GetStatusAsync(userId);
        var daily = await tasks.GetRewardPeriodAsync(userId, QuestType.Daily);
        var weekly = await tasks.GetRewardPeriodAsync(userId, QuestType.Weekly);
        var wallet = await talentProfile.GetSummaryAsync(userId);
        return Ok(new
        {
            wallet = new { wallet.Coins, wallet.Crystals },
            login,
            daily,
            weekly,
        });
    }

    [HttpPost("milestones/{period}/{threshold:int}/claim")]
    public async Task<IActionResult> ClaimMilestone(string period, int threshold)
    {
        if (!Enum.TryParse<QuestType>(period, true, out var type) ||
            type is not (QuestType.Daily or QuestType.Weekly))
            return BadRequest(new { error = "Period must be daily or weekly." });
        try
        {
            return Ok(await tasks.ClaimMilestoneAsync(userContext.UserId, type, threshold));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    /// <summary>Claims every reached-but-unclaimed milestone for the period in one call.
    /// Mirrors <c>POST /season/claim-available</c>.</summary>
    [HttpPost("milestones/{period}/claim-available")]
    public async Task<IActionResult> ClaimAvailableMilestones(string period)
    {
        if (!Enum.TryParse<QuestType>(period, true, out var type) ||
            type is not (QuestType.Daily or QuestType.Weekly))
            return BadRequest(new { error = "Period must be daily or weekly." });
        try
        {
            return Ok(await tasks.ClaimAvailableMilestonesAsync(userContext.UserId, type));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }
}
