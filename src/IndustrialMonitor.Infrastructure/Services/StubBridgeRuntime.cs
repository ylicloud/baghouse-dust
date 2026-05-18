using IndustrialMonitor.Core.Dtos;
using IndustrialMonitor.Core.Interfaces;
using IndustrialMonitor.Infrastructure.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace IndustrialMonitor.Infrastructure.Services;

public sealed class StubBridgeRuntime(
    IOptionsMonitor<BridgeOptions> options,
    ILogger<StubBridgeRuntime> logger) : IBridgeRuntime
{
    public Task<BridgeHeartbeatDto> ExecuteCycleAsync(CancellationToken cancellationToken = default)
    {
        var current = options.CurrentValue;
        var executedAt = DateTimeOffset.UtcNow;

        logger.LogInformation(
            "Bridge cycle executed for source {SourceType} at {Endpoint} on {ExecutedAt}",
            current.SourceType,
            current.SourceEndpoint,
            executedAt);

        var heartbeat = new BridgeHeartbeatDto(
            current.ServiceName,
            current.SourceType,
            current.SourceEndpoint,
            current.PollIntervalSeconds,
            executedAt);

        return Task.FromResult(heartbeat);
    }
}
