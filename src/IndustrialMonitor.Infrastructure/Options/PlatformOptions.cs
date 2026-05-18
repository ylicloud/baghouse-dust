namespace IndustrialMonitor.Infrastructure.Options;

public sealed class PlatformOptions
{
    public const string SectionName = "Platform";

    public string SiteCode { get; set; } = "default-site";

    public string SiteName { get; set; } = "默认站点";

    public string EnvironmentName { get; set; } = "Production";
}
