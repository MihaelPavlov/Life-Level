using System.Text;
using LifeLevel.Api.Application.Adapters;
using LifeLevel.Api.Application.BackgroundJobs;
using LifeLevel.Api.Application.Realtime;
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
using LifeLevel.Modules.Guild.Infrastructure;
using LifeLevel.Modules.Integrations.Application;
using LifeLevel.Modules.Achievements.Infrastructure;
using LifeLevel.Modules.Integrations.Infrastructure;
using LifeLevel.Modules.Notifications;
using LifeLevel.Modules.Seasons.Infrastructure;
using LifeLevel.Modules.Talents.Infrastructure;
using LifeLevel.SharedKernel;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options
        .UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
        .ConfigureWarnings(warnings =>
            warnings.Ignore(RelationalEventId.PendingModelChangesWarning)));

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
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/hubs/guild-raid"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization(opts =>
    opts.AddPolicy("Admin", p => p.RequireRole("Admin")));
builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()));
builder.Services.AddSignalR();

// Shared kernel (registers IEventPublisher)
builder.Services.AddSharedKernel();

// Identity module (registers JwtService + AuthService)
builder.Services.AddIdentityModule();

// Streak module (registers StreakService + port interfaces)
builder.Services.AddStreakModule();

// Character module (registers CharacterService + port interfaces)
// Register after Streak so ActivityLoggedEvent updates streak state before title checks.
builder.Services.AddCharacterModule();

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

// Guild module
builder.Services.AddGuildModule();
builder.Services.AddScoped<IGuildRaidRealtimePort, GuildRaidRealtimePublisher>();

// Achievements module
builder.Services.AddAchievementsModule();

// Notifications module (FCM push, device tokens, cadence policy)
builder.Services.AddNotificationsModule();

// Seasons module (Season Track / Founder Pass — depends on Character/Items/Streak ports)
builder.Services.AddSeasonsModule();

// Talents module (gacha talent cards — depends on Streak port; provides ITalentBonusReadPort)
builder.Services.AddTalentsModule();

// ICharacterCombatStatsReadPort — composition-root adapter over Character +
// Items + Talents + Encounters ports (see CharacterCombatStatsAdapter for
// why no single module can own this without a DI cycle). Registered after
// all four dependency modules above.
builder.Services.AddScoped<ICharacterCombatStatsReadPort, CharacterCombatStatsAdapter>();

// Integrations module
builder.Services.AddIntegrationsModule();
builder.Services.Configure<StravaOptions>(builder.Configuration.GetSection(StravaOptions.Section));
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.StravaOAuthService>();
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.StravaWebhookService>();
builder.Services.Configure<GarminOptions>(builder.Configuration.GetSection(GarminOptions.Section));
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.GarminOAuthService>();
builder.Services.AddHttpClient<LifeLevel.Modules.Integrations.Application.UseCases.GarminWebhookService>();

builder.Services.AddScoped<WorldSeeder>();
builder.Services.AddScoped<ItemSeeder>();
builder.Services.AddScoped<AchievementSeeder>();
builder.Services.AddScoped<TitleSeeder>();
builder.Services.AddScoped<AdminUserSeeder>();
builder.Services.AddScoped<RankThresholdSeeder>();
builder.Services.AddScoped<SeasonSeeder>();
builder.Services.AddScoped<TalentSeeder>();

// User context
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserContext, HttpUserContext>();

// Background jobs
builder.Services.AddHostedService<DailyResetJob>();
builder.Services.AddHostedService<GuildRaidExpiryJob>();
builder.Services.AddHostedService<SeasonRolloverJob>();

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
app.MapHub<GuildRaidHub>("/hubs/guild-raid");
app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "LifeLevel.Api",
    timestamp = DateTimeOffset.UtcNow
}));

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
    try
    {
        await db.Database.MigrateAsync();
    }
    catch (PostgresException ex) when (ex.SqlState == PostgresErrorCodes.DuplicateTable)
    {
        app.Logger.LogWarning(ex, "Skipping duplicate-table migration error during local startup.");
    }

    var seeder = scope.ServiceProvider.GetRequiredService<WorldSeeder>();
    await seeder.SeedAsync();

    var itemSeeder = scope.ServiceProvider.GetRequiredService<ItemSeeder>();
    await itemSeeder.SeedCatalogAsync();
    await itemSeeder.SeedDropRulesAsync();
    await itemSeeder.BackfillLevelReachedRewardsAsync();

    var achievementSeeder = scope.ServiceProvider.GetRequiredService<AchievementSeeder>();
    await achievementSeeder.SeedAsync();

    var titleSeeder = scope.ServiceProvider.GetRequiredService<TitleSeeder>();
    await titleSeeder.SeedAsync();

    var adminSeeder = scope.ServiceProvider.GetRequiredService<AdminUserSeeder>();
    await adminSeeder.SeedAsync();

    var rankSeeder = scope.ServiceProvider.GetRequiredService<RankThresholdSeeder>();
    await rankSeeder.SeedAsync();

    var seasonSeeder = scope.ServiceProvider.GetRequiredService<SeasonSeeder>();
    await seasonSeeder.SeedAsync();

    var talentSeeder = scope.ServiceProvider.GetRequiredService<TalentSeeder>();
    await talentSeeder.SeedAsync();
}

app.Run();
