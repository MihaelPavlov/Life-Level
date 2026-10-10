using System.Data;
using LifeLevel.Api.Infrastructure;
using LifeLevel.Modules.Modes.Application.DTOs;
using LifeLevel.Modules.Modes.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/modes")]
[Authorize]
public class ModesController(ModesService modes, IUserContext user) : ControllerBase
{
    [HttpGet]
    public Task<ModesOverviewDto> Overview(CancellationToken ct) => modes.GetOverviewAsync(user.UserId, ct);

    [HttpGet("burn-chain")]
    public Task<BurnChainDto> BurnStatus(CancellationToken ct) => modes.GetBurnChainAsync(user.UserId, ct);

    [HttpPost("burn-chain/start")]
    [MutationIsolation(IsolationLevel.Serializable)]
    public Task<BurnChainDto> StartBurn(CancellationToken ct) => modes.StartBurnChainAsync(user.UserId, ct);

    [HttpPost("burn-chain/collect")]
    [MutationIsolation(IsolationLevel.Serializable)]
    public Task<BurnChainDto> CollectBurn(CancellationToken ct) => modes.CollectBurnChainAsync(user.UserId, ct);

    [HttpPost("burn-chain/acknowledge-links/{count:int}")]
    public Task<BurnChainDto> AcknowledgeBurn(int count, CancellationToken ct) =>
        modes.AcknowledgeBurnLinksAsync(user.UserId, count, ct);

    [HttpGet("treasure-delve")]
    public Task<TreasureDelveStatusDto> DelveStatus(CancellationToken ct) =>
        modes.GetTreasureDelveAsync(user.UserId, ct);

    [HttpPost("treasure-delve/runs")]
    [MutationIsolation(IsolationLevel.Serializable)]
    public Task<DelveRunDto> StartDelve(CancellationToken ct) => modes.StartDelveAsync(user.UserId, ct);

    [HttpPost("treasure-delve/runs/{runId:guid}/choose")]
    public Task<DelveRunDto> Choose(Guid runId, ChooseDelvePathRequest request, CancellationToken ct) =>
        modes.ChooseDelvePathAsync(user.UserId, runId, request.Path, ct);

    [HttpPost("treasure-delve/runs/{runId:guid}/attempt")]
    [MutationIsolation(IsolationLevel.Serializable)]
    public Task<DelveRunDto> Attempt(Guid runId, CancellationToken ct) => modes.AttemptDelveAsync(user.UserId, runId, ct);

    [HttpPost("treasure-delve/runs/{runId:guid}/continue")]
    public Task<DelveRunDto> Continue(Guid runId, CancellationToken ct) => modes.ContinueDelveAsync(user.UserId, runId, ct);

    [HttpPost("treasure-delve/runs/{runId:guid}/bank")]
    [MutationIsolation(IsolationLevel.Serializable)]
    public Task<DelveRunDto> Bank(Guid runId, CancellationToken ct) => modes.BankDelveAsync(user.UserId, runId, ct);

    [HttpPost("treasure-delve/runs/{runId:guid}/acknowledge")]
    public Task<DelveRunDto> Acknowledge(Guid runId, CancellationToken ct) => modes.AcknowledgeDelveAsync(user.UserId, runId, ct);
}
