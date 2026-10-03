using LifeLevel.Api.Application.Realtime;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Entities;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;

namespace LifeLevel.Api.Tests;

public class StateChangeOwnerResolutionTests
{
    [Fact]
    public async Task GrantingCharacterItem_ResolvesOwnerWithoutExpressionCompilerFailure()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
        var character = new Character { Id = Guid.NewGuid(), UserId = Guid.NewGuid() };
        var httpContext = new DefaultHttpContext();
        httpContext.User = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(ClaimTypes.NameIdentifier, character.UserId.ToString())
        ], "test"));
        var publisher = new StateChangePublisher(null!, new HttpContextAccessor { HttpContext = httpContext },
            NullLogger<StateChangePublisher>.Instance);
        await using var db = new AppDbContext(options, publisher);
        var item = new Item { Id = Guid.NewGuid(), Name = "Test chest reward" };
        db.Characters.Add(character);
        db.Items.Add(item);
        await db.SaveChangesAsync();
        httpContext.Response.Headers.Clear();

        db.CharacterItems.Add(new CharacterItem
        {
            Id = Guid.NewGuid(), CharacterId = character.Id, ItemId = item.Id,
        });

        await db.SaveChangesAsync();
        Assert.Single(await db.CharacterItems.ToListAsync());
        Assert.Contains("inventory", httpContext.Response.Headers[StateChangePublisher.Header].ToString());
    }
}
