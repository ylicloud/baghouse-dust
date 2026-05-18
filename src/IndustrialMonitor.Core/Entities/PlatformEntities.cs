namespace IndustrialMonitor.Core.Entities;

public sealed record PlatformSite(
    long Id,
    string SiteCode,
    string SiteName,
    string TimeZoneId,
    bool IsEnabled);

public sealed record Device(
    long Id,
    long SiteId,
    string DeviceCode,
    string DeviceName,
    string DeviceType,
    string SourceType,
    string? SourceEndpoint,
    bool IsEnabled);

public sealed record TagDefinition(
    long Id,
    long DeviceId,
    string TagCode,
    string TagName,
    string SourceNode,
    string DataType,
    string? Unit,
    int SnapshotIntervalSeconds,
    bool ArchiveEnabled,
    bool IsAlarmSource,
    bool IsEnabled);

public sealed record DeviceStatusSnapshot(
    long DeviceId,
    string RunStatus,
    string FaultStatus,
    string AlarmLevel,
    bool IsOnline,
    DateTimeOffset UpdatedAt);
