FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY LifeLevel.slnx ./
COPY src/LifeLevel.Api/LifeLevel.Api.csproj src/LifeLevel.Api/
COPY src/modules/LifeLevel.SharedKernel/LifeLevel.SharedKernel.csproj src/modules/LifeLevel.SharedKernel/
COPY src/modules/LifeLevel.Modules.Identity/LifeLevel.Modules.Identity.csproj src/modules/LifeLevel.Modules.Identity/
COPY src/modules/LifeLevel.Modules.Character/LifeLevel.Modules.Character.csproj src/modules/LifeLevel.Modules.Character/
COPY src/modules/LifeLevel.Modules.Activity/LifeLevel.Modules.Activity.csproj src/modules/LifeLevel.Modules.Activity/
COPY src/modules/LifeLevel.Modules.Quest/LifeLevel.Modules.Quest.csproj src/modules/LifeLevel.Modules.Quest/
COPY src/modules/LifeLevel.Modules.Streak/LifeLevel.Modules.Streak.csproj src/modules/LifeLevel.Modules.Streak/
COPY src/modules/LifeLevel.Modules.LoginReward/LifeLevel.Modules.LoginReward.csproj src/modules/LifeLevel.Modules.LoginReward/
COPY src/modules/LifeLevel.Modules.Map/LifeLevel.Modules.Map.csproj src/modules/LifeLevel.Modules.Map/
COPY src/modules/LifeLevel.Modules.WorldZone/LifeLevel.Modules.WorldZone.csproj src/modules/LifeLevel.Modules.WorldZone/
COPY src/modules/LifeLevel.Modules.Adventure.Encounters/LifeLevel.Modules.Adventure.Encounters.csproj src/modules/LifeLevel.Modules.Adventure.Encounters/
COPY src/modules/LifeLevel.Modules.Adventure.Dungeons/LifeLevel.Modules.Adventure.Dungeons.csproj src/modules/LifeLevel.Modules.Adventure.Dungeons/
COPY src/modules/LifeLevel.Modules.Items/LifeLevel.Modules.Items.csproj src/modules/LifeLevel.Modules.Items/
COPY src/modules/LifeLevel.Modules.Integrations/LifeLevel.Modules.Integrations.csproj src/modules/LifeLevel.Modules.Integrations/
COPY src/modules/LifeLevel.Modules.Achievements/LifeLevel.Modules.Achievements.csproj src/modules/LifeLevel.Modules.Achievements/
COPY src/modules/LifeLevel.Modules.Notifications/LifeLevel.Modules.Notifications.csproj src/modules/LifeLevel.Modules.Notifications/

RUN dotnet restore src/LifeLevel.Api/LifeLevel.Api.csproj

COPY . .
RUN dotnet publish src/LifeLevel.Api/LifeLevel.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 10000
ENTRYPOINT ["sh", "-c", "ASPNETCORE_URLS=http://0.0.0.0:${PORT:-10000} dotnet LifeLevel.Api.dll"]
