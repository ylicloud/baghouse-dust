using IndustrialMonitor.Core.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace IndustrialMonitor.Web.Controllers;

[ApiController]
[Route("api/platform")]
public sealed class PlatformController(IPlatformSummaryService summaryService) : ControllerBase
{
    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        var summary = await summaryService.GetSummaryAsync(cancellationToken);
        return Ok(summary);
    }
}
