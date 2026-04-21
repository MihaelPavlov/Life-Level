using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/tutorial")]
[Authorize]
public class TutorialController(
    CharacterService characterService,
    IUserContext userContext) : ControllerBase
{
    [HttpPost("advance")]
    public async Task<IActionResult> Advance(CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var (newStep, xpAwarded) = await characterService.AdvanceTutorialAsync(userId, ct);
            var (_, topicsSeen) = await characterService.GetTutorialStateAsync(userId, ct);
            return Ok(new AdvanceTutorialResponse(newStep, topicsSeen, xpAwarded));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("skip")]
    public async Task<IActionResult> Skip(CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            await characterService.SkipTutorialAsync(userId, ct);
            var (step, topicsSeen) = await characterService.GetTutorialStateAsync(userId, ct);
            return Ok(new SkipTutorialResponse(step, topicsSeen));
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPost("replay-all")]
    public async Task<IActionResult> ReplayAll(CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            await characterService.ReplayAllAsync(userId, ct);
            var (step, topicsSeen) = await characterService.GetTutorialStateAsync(userId, ct);
            return Ok(new ReplayAllTutorialResponse(step, topicsSeen));
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPost("replay-topic")]
    public async Task<IActionResult> ReplayTopic([FromBody] ReplayTopicRequest req, CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            await characterService.ReplayTopicAsync(userId, req.Topic, ct);
            var (step, topicsSeen) = await characterService.GetTutorialStateAsync(userId, ct);
            return Ok(new ReplayTopicResponse(step, topicsSeen));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
