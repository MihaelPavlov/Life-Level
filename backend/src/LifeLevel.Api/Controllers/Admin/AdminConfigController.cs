using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/config")]
public class AdminConfigController(IConfiguration config) : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok(new
    {
        email = config["Admin:Email"] ?? "local@lifelevel.com",
        password = config["Admin:Password"] ?? "1qaz!QAZ",
    });
}
  