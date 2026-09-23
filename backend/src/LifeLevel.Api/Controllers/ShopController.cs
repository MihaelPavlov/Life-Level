using LifeLevel.Modules.Items.Application.DTOs;
using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/shop")]
[Authorize]
public class ShopController(ShopService shop, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public Task<ShopResponse> Get(CancellationToken ct) => shop.GetAsync(userContext.UserId, ct);

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh(CancellationToken ct) =>
        await Run(() => shop.RefreshAsync(userContext.UserId, ct));

    [HttpPost("items/{itemId:guid}/purchase")]
    public async Task<IActionResult> PurchaseItem(Guid itemId, ShopPurchaseRequest request, CancellationToken ct) =>
        await Run(() => shop.PurchaseItemAsync(userContext.UserId, itemId, request.ClientPurchaseId, ct));

    [HttpPost("chests/{tier}/purchase")]
    public async Task<IActionResult> PurchaseChest(string tier, ShopPurchaseRequest request, CancellationToken ct) =>
        await Run(() => shop.PurchaseChestAsync(userContext.UserId, tier, request.ClientPurchaseId, ct));

    private async Task<IActionResult> Run<T>(Func<Task<T>> action)
    {
        try { return Ok(await action()); }
        catch (ShopException ex) { return Conflict(new { code = ex.Code, message = ex.Message }); }
    }
}
