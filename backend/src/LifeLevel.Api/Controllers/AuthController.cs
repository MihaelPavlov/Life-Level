using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LifeLevel.Modules.Identity.Infrastructure;
using Microsoft.AspNetCore.RateLimiting;

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
    [EnableRateLimiting("auth")]
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

    [HttpPost("google")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Google(GoogleAuthRequest req, CancellationToken ct)
    {
        try
        {
            return Ok(await authService.GoogleAsync(req, ct));
        }
        catch (GoogleAccountLinkRequiredException ex)
        {
            return Conflict(new { code = "account_link_required", error = ex.Message });
        }
        catch (InvalidGoogleLinkPasswordException ex)
        {
            return Unauthorized(new { code = "invalid_link_password", error = ex.Message });
        }
        catch (InvalidGoogleTokenException ex)
        {
            return Unauthorized(new { code = "invalid_google_token", error = ex.Message });
        }
        catch (GoogleAuthUnavailableException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new { code = "google_auth_unavailable", error = ex.Message });
        }
    }

    [HttpPost("apple")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Apple(AppleAuthRequest req, CancellationToken ct)
    {
        try
        {
            return Ok(await authService.AppleAsync(req, ct));
        }
        catch (AccountLinkRequiredException ex)
        {
            return Conflict(new { code = "account_link_required", error = ex.Message });
        }
        catch (InvalidLinkPasswordException ex)
        {
            return Unauthorized(new { code = "invalid_link_password", error = ex.Message });
        }
        catch (ExternalEmailMissingException ex)
        {
            return BadRequest(new { code = "email_missing", error = ex.Message });
        }
        catch (InvalidAppleTokenException ex)
        {
            return Unauthorized(new { code = "invalid_apple_token", error = ex.Message });
        }
        catch (AppleAuthUnavailableException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new { code = "apple_auth_unavailable", error = ex.Message });
        }
    }

    [HttpGet("account")]
    [Authorize]
    public async Task<IActionResult> GetAccount(CancellationToken ct)
    {
        var result = await accountService.GetAsync(userContext.UserId, ct);
        return Ok(result);
    }

    [HttpGet("username/available")]
    [Authorize]
    public async Task<IActionResult> UsernameAvailable(
        [FromQuery] string? username,
        CancellationToken ct)
    {
        var problem = await accountService.UsernameProblemAsync(userContext.UserId, username, ct);
        return Ok(new UsernameAvailabilityResponse(problem is null, problem));
    }

    [HttpPut("username")]
    [Authorize]
    public async Task<IActionResult> ChooseUsername(ChooseUsernameRequest req, CancellationToken ct)
    {
        try
        {
            return Ok(await accountService.ChooseUsernameAsync(userContext.UserId, req, ct));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
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

    [HttpPost("password")]
    [Authorize]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> SetPasswordWithGoogle(
        SetPasswordWithGoogleRequest req,
        CancellationToken ct)
    {
        try
        {
            await accountService.SetPasswordWithGoogleAsync(userContext.UserId, req, ct);
            return NoContent();
        }
        catch (InvalidGoogleTokenException ex)
        {
            return Unauthorized(new { error = ex.Message });
        }
        catch (GoogleAuthUnavailableException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
