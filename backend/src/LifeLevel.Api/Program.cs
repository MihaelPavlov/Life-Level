using System.Text;
using LifeLevel.Api.Application;
using LifeLevel.Api.Application.BackgroundJobs;
using LifeLevel.Api.Application.Services;
using LifeLevel.Api.Infrastructure;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

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

builder.Services.AddAuthorization();
builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()));

// App services
builder.Services.AddScoped<JwtService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<StreakService>();
builder.Services.AddScoped<CharacterService>();
builder.Services.AddScoped<LoginRewardService>();
builder.Services.AddScoped<QuestService>();
builder.Services.AddScoped<ActivityService>();
builder.Services.AddScoped<MapService>();
builder.Services.AddScoped<WorldZoneService>();
builder.Services.AddScoped<BossService>();
builder.Services.AddScoped<ChestService>();
builder.Services.AddScoped<DungeonService>();
builder.Services.AddScoped<CrossroadsService>();

// User context
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserContext, HttpUserContext>();

// Background jobs
builder.Services.AddHostedService<DailyResetJob>();

// CORS — allow Flutter dev clients + local HTML files (Origin: null from file://)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.SetIsOriginAllowed(_ => true).AllowAnyMethod().AllowAnyHeader());
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

app.UseCors("AllowAll");
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

app.Run();
