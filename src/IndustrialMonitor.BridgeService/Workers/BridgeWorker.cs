using IndustrialMonitor.Core.Interfaces;
using IndustrialMonitor.Infrastructure.Options;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace IndustrialMonitor.BridgeService.Workers;

public sealed class BridgeWorker(
    IBridgeRuntime bridgeRuntime,
    IOptionsMonitor<BridgeOptions> options,
    ILogger<BridgeWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Bridge worker started at {StartedAt}", DateTimeOffset.UtcNow);

        while (!stoppingToken.IsCancellationRequested)
        {
            var heartbeat = await bridgeRuntime.ExecuteCycleAsync(stoppingToken);

            logger.LogInformation(
                "Bridge heartbeat: {ServiceName} -> {SourceType} ({Endpoint}) at {ExecutedAt}",
                heartbeat.ServiceName,
                heartbeat.SourceType,
                heartbeat.SourceEndpoint,
                heartbeat.ExecutedAt);

            var interval = Math.Max(1, options.CurrentValue.PollIntervalSeconds);
            await Task.Delay(TimeSpan.FromSeconds(interval), stoppingToken);
        }
    }
}
