using System.Security.Claims;
using LifeLevel.Api.Application.Services;
using LifeLevel.Api.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/quests")]
[Authorize]
public class QuestController(QuestService questService) : ControllerBase
{
    [HttpGet("daily")]
    public async Task<IActionResult> GetDaily()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var quests = await questService.GetActiveQuestsAsync(userId, QuestType.Daily);
        if (quests.Count == 0)
        {
            await questService.GenerateDailyQuestsAsync(userId);
            quests = await questService.GetActiveQuestsAsync(userId, QuestType.Daily);
        }
        return Ok(quests);
    }

    [HttpGet("weekly")]
    public async Task<IActionResult> GetWeekly()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var quests = await questService.GetActiveQuestsAsync(userId, QuestType.Weekly);
        if (quests.Count == 0)
        {
            await questService.GenerateWeeklyQuestsAsync(userId);
            quests = await questService.GetActiveQuestsAsync(userId, QuestType.Weekly);
        }
        return Ok(quests);
    }

    [HttpGet("special")]
    public async Task<IActionResult> GetSpecial()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var quests = await questService.GetActiveQuestsAsync(userId, QuestType.Special);
        return Ok(quests);
    }

    [HttpPost("generate/daily")]
    public async Task<IActionResult> GenerateDaily()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await questService.GenerateDailyQuestsAsync(userId);
        var quests = await questService.GetActiveQuestsAsync(userId, QuestType.Daily);
        return Ok(quests);
    }

    [HttpPost("generate/weekly")]
    public async Task<IActionResult> GenerateWeekly()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await questService.GenerateWeeklyQuestsAsync(userId);
        var quests = await questService.GetActiveQuestsAsync(userId, QuestType.Weekly);
        return Ok(quests);
    }
}
