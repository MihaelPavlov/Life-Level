using LifeLevel.Api.Application.DTOs.Auth;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AuthService authService) : ControllerBase
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
}
