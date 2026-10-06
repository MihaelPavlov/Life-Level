using System.Text;
using LifeLevel.Modules.Waitlist.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/waitlist")]
[Authorize(Policy = "Admin")]
public class AdminWaitlistController(WaitlistService waitlist) : ControllerBase
{
    [HttpGet("stats")]
    public async Task<IActionResult> Stats(CancellationToken ct) =>
        Ok(await waitlist.GetStatsAsync(ct));

    [HttpGet]
    public async Task<IActionResult> List(int page = 1, int size = 50, CancellationToken ct = default) =>
        Ok(await waitlist.ListAsync(page, size, ct));

    [HttpGet("export")]
    public async Task<IActionResult> Export(CancellationToken ct)
    {
        var csv = await waitlist.ExportCsvAsync(ct);
        return File(Encoding.UTF8.GetBytes(csv), "text/csv",
            $"lifelevel-waitlist-{DateTime.UtcNow:yyyy-MM-dd}.csv");
    }
}
