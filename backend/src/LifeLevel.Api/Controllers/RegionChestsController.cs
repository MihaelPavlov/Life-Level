using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/world/region-chests")]
public class RegionChestsController(RegionChestService chests, IUserContext user) : ControllerBase
{
    [HttpGet]
    public Task<RegionChestsDto> Get(CancellationToken ct) => chests.GetAsync(user.UserId, ct);

    [HttpPost("{regionId:guid}/claim")]
    public async Task<IActionResult> Claim(Guid regionId, CancellationToken ct) =>
        Ok(await chests.ClaimAsync(user.UserId, regionId, ct));
}
