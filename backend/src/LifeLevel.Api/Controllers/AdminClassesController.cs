using LifeLevel.Api.Application.DTOs.CharacterClass;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/admin/classes")]
[Authorize(Roles = "Admin")]
public class AdminClassesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await db.CharacterClasses.OrderBy(c => c.Name).ToListAsync());

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var cls = await db.CharacterClasses.FindAsync(id);
        return cls is null ? NotFound() : Ok(cls);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateClassRequest req)
    {
        var cls = new CharacterClass
        {
            Id = Guid.NewGuid(),
            Name = req.Name,
            Emoji = req.Emoji,
            Description = req.Description,
            Tagline = req.Tagline,
            StrMultiplier = req.StrMultiplier,
            EndMultiplier = req.EndMultiplier,
            AgiMultiplier = req.AgiMultiplier,
            FlxMultiplier = req.FlxMultiplier,
            StaMultiplier = req.StaMultiplier,
        };
        db.CharacterClasses.Add(cls);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = cls.Id }, cls);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateClassRequest req)
    {
        var cls = await db.CharacterClasses.FindAsync(id);
        if (cls is null) return NotFound();
        cls.Name = req.Name;
        cls.Emoji = req.Emoji;
        cls.Description = req.Description;
        cls.Tagline = req.Tagline;
        cls.StrMultiplier = req.StrMultiplier;
        cls.EndMultiplier = req.EndMultiplier;
        cls.AgiMultiplier = req.AgiMultiplier;
        cls.FlxMultiplier = req.FlxMultiplier;
        cls.StaMultiplier = req.StaMultiplier;
        cls.IsActive = req.IsActive;
        await db.SaveChangesAsync();
        return Ok(cls);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        var cls = await db.CharacterClasses.FindAsync(id);
        if (cls is null) return NotFound();
        cls.IsActive = false;
        await db.SaveChangesAsync();
        return NoContent();
    }
}
