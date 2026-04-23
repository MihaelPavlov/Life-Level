using LifeLevel.SharedKernel.Contracts;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

/// <summary>
/// Read-side endpoints for the v3 World Map (spec §12 of
/// <c>design-mockup/map/WORLD-MAP-FINAL-DESIGN.md</c>). Two-level navigation:
/// the world screen fetches <c>GET /api/map/world</c>; tapping into a region
/// fetches <c>GET /api/map/region/{id}</c>.
///
/// Kept separate from the existing <see cref="MapController"/> (which owns the
/// dungeon/node layer at <c>/api/map/full</c>) so the two layers stay
/// independently routable.
/// </summary>
[ApiController]
[Authorize]
[Route("api/map")]
public class WorldMapController(MapReadService mapRead, IUserContext userContext) : ControllerBase
{
    [HttpGet("world")]
    public async Task<ActionResult<WorldMapDto>> GetWorld(CancellationToken ct)
    {
        var userId = userContext.UserId;
        var dto = await mapRead.GetWorldMapAsync(userId, ct);
        return Ok(dto);
    }

    [HttpGet("region/{id:guid}")]
    public async Task<ActionResult<RegionDetailDto>> GetRegion(Guid id, CancellationToken ct)
    {
        var userId = userContext.UserId;
        var dto = await mapRead.GetRegionDetailAsync(userId, id, ct);
        return dto == null ? NotFound(new { message = "Region not found." }) : Ok(dto);
    }
}
