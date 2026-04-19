using System.Text;
using LifeLevel.Api.Application.Adapters;
using LifeLevel.Api.Application.BackgroundJobs;
using LifeLevel.Api.Application.Services;
using LifeLevel.Api.Infrastructure;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Activity.Infrastructure;
using LifeLevel.Modules.Adventure.Dungeons.Infrastructure;
using LifeLevel.Modules.Adventure.Encounters.Infrastructure;
using LifeLevel.Modules.Character.Infrastructure;
using LifeLevel.Modules.Identity.Infrastructure;
using LifeLevel.Modules.LoginReward.Infrastructure;
using LifeLevel.Modules.Map.Infrastructure;
using LifeLevel.Modules.Quest.Infrastructure;
using LifeLevel.Modules.Streak.Infrastructure;
using LifeLevel.Modules.WorldZone.Infrastructure;
using LifeLevel.Modules.Items.Infrastructure;
using LifeLevel.Modules.Integrations.Application;
using LifeLevel.Modules.Achievements.Infrastructure;
using LifeLevel.Modules.Integrations.Infrastructure;
using LifeLevel.Modules.Notifications;
using LifeLevel.SharedKernel;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register DbContext as base type so modules can inject it
builder.Services.AddScoped<DbContext>(sp => sp.GetRequiredService<AppDbContext>());

// JWT Auth
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key is not configured.");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization(opts =>
    opts.AddPolicy("Admin", p => p.RequireRole("Admin")));
builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()));

// Shared kernel (registers IEventPublisher)
builder.Services.AddSharedKernel();

// Identity module (registers JwtService + AuthService)
builder.Services.AddIdentityModule();

// Character module (registers CharacterService + port interfaces)
builder.Services.AddCharacterModule();

// Streak module (registers StreakService + port interfaces)
builder.Services.AddStreakModule();

// IUserReadPort — now served by CharacterModule's CharacterService via Identity module UserReadPortAdapter
builder.Services.AddScoped<IUserReadPort>(sp =>
    new UserReadPortAdapter(sp.GetRequiredService<AppDbContext>()));

// Quest module
builder.Services.AddQuestModule();

// Activity module
builder.Services.AddActivityModule();

// LoginReward module
builder.Services.AddLoginRewardModule();

// WorldZone module
builder.Services.AddWorldZoneModule();

// Map module (entities + EF configs + IMapProgressReadPort)
builder.Services.AddMapModule();

// Adventure.Encounters module (BossService + ChestService)
builder.Services.AddEncountersModule();

// Adventure.Dungeons module (DungeonService + CrossroadsService)
builder.Services.AddDungeonsModule();

// Items module
builder.Services.AddItemsModule();

// Achievements module
builder.Services.AddAchievementsModule();

// Notifications module (FCM push, device tokens, cadence policy)
builder.Services.AddNotificationsModule();

// Integrations module
builder.Services.AddIntegrationsModule();
builder.Services.Configure<StravaOptions>(builder.Configuration.GetSection(StravaOptions.Section));
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.StravaOAuthService>();
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.StravaWebhookService>();
builder.Services.Configure<GarminOptions>(builder.Configuration.GetSection(GarminOptions.Section));
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.GarminOAuthService>();
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.GarminWebhookService>();

// App services (MapService stays in LifeLevel.Api)
builder.Services.AddScoped<MapService>();
builder.Services.AddScoped<IMapDistancePort>(sp => sp.GetRequiredService<MapService>());
builder.Services.AddScoped<WorldSeeder>();
builder.Services.AddScoped<ItemSeeder>();
builder.Services.AddScoped<AchievementSeeder>();
builder.Services.AddScoped<TitleSeeder>();

// User context
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserContext, HttpUserContext>();

// Background jobs
builder.Services.AddHostedService<DailyResetJob>();

// CORS — allow Flutter dev clients + local HTML files (Origin: null from file://)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.SetIsOriginAllowed(_ => true).AllowAnyMethod().AllowAnyHeader().AllowCredentials());
});

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "LifeLevel API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Description = "Enter: Bearer {token}",
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            []
        }
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors("AllowAll");
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Serve the HTML admin panel
app.MapGet("/admin-map", (IWebHostEnvironment env) =>
{
    var path = Path.GetFullPath(
        Path.Combine(env.ContentRootPath, "..", "..", "..", "design-mockup", "admin-map.html"));
    return File.Exists(path)
        ? Results.File(path, "text/html")
        : Results.NotFound("admin-map.html not found");
});

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();

    var seeder = scope.ServiceProvider.GetRequiredService<WorldSeeder>();
    await seeder.SeedAsync();

    var itemSeeder = scope.ServiceProvider.GetRequiredService<ItemSeeder>();
    await itemSeeder.SeedCatalogAsync();
    await itemSeeder.SeedDropRulesAsync();

    var achievementSeeder = scope.ServiceProvider.GetRequiredService<AchievementSeeder>();
    await achievementSeeder.SeedAsync();

    var titleSeeder = scope.ServiceProvider.GetRequiredService<TitleSeeder>();
    await titleSeeder.SeedAsync();
}

app.Run();
