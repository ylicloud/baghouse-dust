using IndustrialMonitor.Infrastructure.Extensions;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddIndustrialMonitorInfrastructure(builder.Configuration);
builder.Services.AddControllers();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseExceptionHandler();
app.UseHttpsRedirection();

app.MapGet("/", () =>
    Results.Content(
        """
        <html>
        <head><meta charset="utf-8" /><title>IndustrialMonitor.Web</title></head>
        <body>
            <h1>IndustrialMonitor.Web</h1>
            <p>平台骨架已生成。</p>
            <ul>
                <li><a href="/health">/health</a></li>
                <li><a href="/api/platform/summary">/api/platform/summary</a></li>
            </ul>
        </body>
        </html>
        """,
        "text/html; charset=utf-8"));

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "IndustrialMonitor.Web",
    framework = ".NET 10",
    timestamp = DateTimeOffset.UtcNow
}));

app.MapControllers();

app.Run();
