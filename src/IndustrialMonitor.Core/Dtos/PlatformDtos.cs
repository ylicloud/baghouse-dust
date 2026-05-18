namespace IndustrialMonitor.Core.Dtos;

public sealed record PlatformSummaryDto(
    string SiteCode,
    string SiteName,
    int DeviceCount,
    int OnlineDeviceCount,
    int ActiveAlarmCount,
    DateTimeOffset GeneratedAt);

public sealed record BridgeHeartbeatDto(
    string ServiceName,
    string SourceType,
    string SourceEndpoint,
    int PollIntervalSeconds,
    DateTimeOffset ExecutedAt);
