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
            var mapStep = await characterService.GetMapTutorialStepAsync(userId, ct);
            return Ok(new AdvanceTutorialResponse(newStep, topicsSeen, mapStep, xpAwarded));
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
            var mapStep = await characterService.GetMapTutorialStepAsync(userId, ct);
            return Ok(new SkipTutorialResponse(step, topicsSeen, mapStep));
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
            var mapStep = await characterService.GetMapTutorialStepAsync(userId, ct);
            return Ok(new ReplayAllTutorialResponse(step, topicsSeen, mapStep));
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
            var mapStep = await characterService.GetMapTutorialStepAsync(userId, ct);
            return Ok(new ReplayTopicResponse(step, topicsSeen, mapStep));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("map/start")]
    public async Task<IActionResult> StartMap(CancellationToken ct)
    {
        var step = await characterService.StartMapTutorialAsync(userContext.UserId, ct);
        return Ok(new MapTutorialResponse(step));
    }

    [HttpPost("map/advance")]
    public async Task<IActionResult> AdvanceMap(CancellationToken ct)
    {
        var step = await characterService.AdvanceMapTutorialAsync(userContext.UserId, ct);
        return Ok(new MapTutorialResponse(step));
    }

    [HttpPost("map/skip")]
    public async Task<IActionResult> SkipMap(CancellationToken ct)
    {
        var step = await characterService.SkipMapTutorialAsync(userContext.UserId, ct);
        return Ok(new MapTutorialResponse(step));
    }

    [HttpPost("map/replay")]
    public async Task<IActionResult> ReplayMap(CancellationToken ct)
    {
        var step = await characterService.ReplayMapTutorialAsync(userContext.UserId, ct);
        return Ok(new MapTutorialResponse(step));
    }
}
