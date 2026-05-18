using IndustrialMonitor.Core.Interfaces;
using IndustrialMonitor.Infrastructure.Options;
using IndustrialMonitor.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace IndustrialMonitor.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddIndustrialMonitorInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services
            .AddOptions<PlatformOptions>()
            .Bind(configuration.GetSection(PlatformOptions.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services
            .AddOptions<BridgeOptions>()
            .Bind(configuration.GetSection(BridgeOptions.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddSingleton<IPlatformSummaryService, InMemoryPlatformSummaryService>();
        services.AddSingleton<IBridgeRuntime, StubBridgeRuntime>();

        return services;
    }
}
