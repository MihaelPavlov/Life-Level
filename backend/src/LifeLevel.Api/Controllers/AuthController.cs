using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(
    AuthService authService,
    AccountService accountService,
    IUserContext userContext) : ControllerBase
{
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        try
        {
            var result = await authService.RegisterAsync(req);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req)
    {
        try
        {
            var result = await authService.LoginAsync(req);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Unauthorized(new { error = ex.Message });
        }
    }

    [HttpGet("account")]
    [Authorize]
    public async Task<IActionResult> GetAccount(CancellationToken ct)
    {
        var result = await accountService.GetAsync(userContext.UserId, ct);
        return Ok(result);
    }

    [HttpPut("email")]
    [Authorize]
    public async Task<IActionResult> UpdateEmail(UpdateEmailRequest req, CancellationToken ct)
    {
        try
        {
            var result = await accountService.UpdateEmailAsync(userContext.UserId, req, ct);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest req, CancellationToken ct)
    {
        try
        {
            await accountService.ChangePasswordAsync(userContext.UserId, req, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
