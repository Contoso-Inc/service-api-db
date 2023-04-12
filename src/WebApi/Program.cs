using System.Text.Json;
using WebApi.Ops;
using WebApi.Services;

namespace WebApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            
            var apiName = builder.Configuration.GetValue<string>("ApiName");
            builder.AddOps(args);
            builder.Services.AddHttpClient();
            builder.Services.AddHttpContextAccessor();

            builder.Services.AddSingleton<IEnvHealthCheck, EnvHealthCheck>();
            builder.Services.AddHealthChecks().AddCheck<IEnvHealthCheck>(
                "EnvHealthy",
                tags: new [] { HealthTag.Live }
            );

            // Add services to the container.
            builder.Services.AddHostedService<StartupBackgroundService>();

            builder.Services.AddControllers()
                                .AddJsonOptions(option => option.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase);

            builder.Services.AddEndpointsApiExplorer();

            var app = builder.Build();

            app.ConfigOps();

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}