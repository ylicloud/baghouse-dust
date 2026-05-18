using IndustrialMonitor.Infrastructure.Extensions;
using IndustrialMonitor.BridgeService.Workers;
using Microsoft.Extensions.Hosting;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddIndustrialMonitorInfrastructure(builder.Configuration);
builder.Services.AddHostedService<BridgeWorker>();

var host = builder.Build();
await host.RunAsync();
