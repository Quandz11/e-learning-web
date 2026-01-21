# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["e-learning-server.csproj", "./"]
RUN dotnet restore "e-learning-server.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "e-learning-server.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "e-learning-server.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Copy published app
COPY --from=publish /app/publish .

# Expose port 8080 (default for Azure App Service)
EXPOSE 8080

# Set environment variable for ASP.NET Core
ENV ASPNETCORE_URLS=http://+:8080

# Run the application
ENTRYPOINT ["dotnet", "e-learning-server.dll"]
