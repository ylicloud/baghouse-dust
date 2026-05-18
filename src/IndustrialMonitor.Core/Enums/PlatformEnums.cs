namespace IndustrialMonitor.Core.Enums;

public enum DeviceSourceType
{
    OpcUa = 1,
    WinCc = 2,
    Other = 99
}

public enum AlarmSeverity
{
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4
}
