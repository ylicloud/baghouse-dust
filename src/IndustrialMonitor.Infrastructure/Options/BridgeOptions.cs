namespace IndustrialMonitor.Infrastructure.Options;

public sealed class BridgeOptions
{
    public const string SectionName = "Bridge";

    public string ServiceName { get; set; } = "IndustrialMonitor.BridgeService";

    public string SourceType { get; set; } = "opcua";

    public string SourceEndpoint { get; set; } = "opc.tcp://127.0.0.1:49320";

    public int PollIntervalSeconds { get; set; } = 5;
}
