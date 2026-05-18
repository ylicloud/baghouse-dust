using IndustrialMonitor.Core.Dtos;

namespace IndustrialMonitor.Core.Interfaces;

public interface IPlatformSummaryService
{
    Task<PlatformSummaryDto> GetSummaryAsync(CancellationToken cancellationToken = default);
}

public interface IBridgeRuntime
{
    Task<BridgeHeartbeatDto> ExecuteCycleAsync(CancellationToken cancellationToken = default);
}
