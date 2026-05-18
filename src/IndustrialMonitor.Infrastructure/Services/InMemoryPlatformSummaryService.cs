using IndustrialMonitor.Core.Dtos;
using IndustrialMonitor.Core.Interfaces;
using IndustrialMonitor.Infrastructure.Options;
using Microsoft.Extensions.Options;

namespace IndustrialMonitor.Infrastructure.Services;

public sealed class InMemoryPlatformSummaryService(IOptionsMonitor<PlatformOptions> options) : IPlatformSummaryService
{
    public Task<PlatformSummaryDto> GetSummaryAsync(CancellationToken cancellationToken = default)
    {
        var current = options.CurrentValue;

        var summary = new PlatformSummaryDto(
            current.SiteCode,
            current.SiteName,
            DeviceCount: 0,
            OnlineDeviceCount: 0,
            ActiveAlarmCount: 0,
            GeneratedAt: DateTimeOffset.UtcNow);

        return Task.FromResult(summary);
    }
}
