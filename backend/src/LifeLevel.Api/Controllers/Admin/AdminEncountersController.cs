using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/encounters")]
[Authorize(Policy = "Admin")]
public class AdminEncountersController(AppDbContext db) : ControllerBase
{
    // GET /api/admin/encounters?regionId=X
    [HttpGet]
    public async Task<IActionResult> GetByRegion([FromQuery] Guid regionId)
    {
        var templates = await db.TrailEncounterTemplates
            .Where(t => t.RegionId == regionId)
            .OrderBy(t => t.Type)
            .ThenBy(t => t.Name)
            .Select(t => new
            {
                t.Id,
                t.Type,
                t.Name,
                t.Emoji,
                t.SpawnChance,
                t.IsActive,
                t.PinnedFromZoneId,
                t.PinnedToZoneId,
                t.PositionFraction
            })
            .ToListAsync();

        return Ok(templates);
    }

    // GET /api/admin/encounters/{id}
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var template = await db.TrailEncounterTemplates.FindAsync(id);
        if (template == null) return NotFound();

        return Ok(new
        {
            template.Id,
            template.RegionId,
            template.Type,
            template.Name,
            template.Emoji,
            template.SpawnChance,
            template.IsActive,
            template.ConfigJson,
            template.CreatedAt,
            template.PinnedFromZoneId,
            template.PinnedToZoneId,
            template.PositionFraction
        });
    }

    // GET /api/admin/encounters/zones?regionId=X  — list zones in a region for the dropdowns
    [HttpGet("zones")]
    public async Task<IActionResult> GetZonesForRegion([FromQuery] Guid regionId)
    {
        var zones = await db.WorldZones
            .Where(z => z.RegionId == regionId)
            .OrderBy(z => z.Name)
            .Select(z => new { z.Id, z.Name, z.Emoji })
            .ToListAsync();
        return Ok(zones);
    }

    // POST /api/admin/encounters
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UpsertEncounterRequest req)
    {
        if (!await db.Regions.AnyAsync(r => r.Id == req.RegionId))
            return NotFound("Region not found.");

        var template = new TrailEncounterTemplate
        {
            Id = Guid.NewGuid(),
            RegionId = req.RegionId,
            Type = req.Type.Trim(),
            Name = req.Name.Trim(),
            Emoji = req.Emoji.Trim(),
            SpawnChance = Math.Clamp(req.SpawnChance, 0.0, 1.0),
            IsActive = req.IsActive,
            ConfigJson = string.IsNullOrWhiteSpace(req.ConfigJson) ? "{}" : req.ConfigJson.Trim(),
            PinnedFromZoneId = req.PinnedFromZoneId,
            PinnedToZoneId = req.PinnedToZoneId,
            PositionFraction = req.PositionFraction.HasValue
                ? Math.Clamp(req.PositionFraction.Value, 0.0, 1.0)
                : null,
            CreatedAt = DateTimeOffset.UtcNow
        };

        db.TrailEncounterTemplates.Add(template);
        await db.SaveChangesAsync();
        return Ok(new { template.Id });
    }

    // PUT /api/admin/encounters/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpsertEncounterRequest req)
    {
        var template = await db.TrailEncounterTemplates.FindAsync(id);
        if (template == null) return NotFound();

        template.Type = req.Type.Trim();
        template.Name = req.Name.Trim();
        template.Emoji = req.Emoji.Trim();
        template.SpawnChance = Math.Clamp(req.SpawnChance, 0.0, 1.0);
        template.IsActive = req.IsActive;
        template.ConfigJson = string.IsNullOrWhiteSpace(req.ConfigJson) ? "{}" : req.ConfigJson.Trim();
        template.PinnedFromZoneId = req.PinnedFromZoneId;
        template.PinnedToZoneId = req.PinnedToZoneId;
        template.PositionFraction = req.PositionFraction.HasValue
            ? Math.Clamp(req.PositionFraction.Value, 0.0, 1.0)
            : null;

        await db.SaveChangesAsync();
        return Ok();
    }

    // DELETE /api/admin/encounters/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var template = await db.TrailEncounterTemplates.FindAsync(id);
        if (template == null) return NotFound();

        db.TrailEncounterTemplates.Remove(template);
        await db.SaveChangesAsync();
        return Ok();
    }
}

public record UpsertEncounterRequest(
    Guid RegionId,
    string Type,
    string Name,
    string Emoji,
    double SpawnChance,
    bool IsActive,
    string ConfigJson,
    Guid? PinnedFromZoneId = null,
    Guid? PinnedToZoneId = null,
    double? PositionFraction = null);
