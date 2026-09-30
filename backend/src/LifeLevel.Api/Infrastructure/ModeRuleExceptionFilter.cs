using LifeLevel.Modules.Modes.Application.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace LifeLevel.Api.Infrastructure;

public class ModeRuleExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        if (context.Exception is ModeRuleException rule)
        {
            context.Result = new ConflictObjectResult(new { code = rule.Code, message = rule.Message });
            context.ExceptionHandled = true;
        }
        else if (context.Exception is KeyNotFoundException missing)
        {
            context.Result = new NotFoundObjectResult(new { code = "not_found", message = missing.Message });
            context.ExceptionHandled = true;
        }
    }
}
