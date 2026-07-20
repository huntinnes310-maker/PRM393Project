# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY GymSupport.API/GymSupport.API.csproj GymSupport.API/
COPY GymSupport.Repository/GymSupport.Repository.csproj GymSupport.Repository/
COPY GymSupport.Service/GymSupport.Service.csproj GymSupport.Service/
RUN dotnet restore GymSupport.API/GymSupport.API.csproj

COPY . .
RUN dotnet publish GymSupport.API/GymSupport.API.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "GymSupport.API.dll"]
