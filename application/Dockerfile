FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY PiranhaDemo/PiranhaDemo.csproj PiranhaDemo/
RUN dotnet restore PiranhaDemo/PiranhaDemo.csproj
COPY PiranhaDemo/ PiranhaDemo/
RUN dotnet publish PiranhaDemo/PiranhaDemo.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build --chown=$APP_UID /app .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "PiranhaDemo.dll"]
