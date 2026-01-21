## CI/CD to Azure with Docker & GitHub Actions (Free Tier Friendly)

This doc shows how to containerize the API and deploy it to Azure using GitHub Actions (free runner) plus Azure resources that fit the free/low tier. Frontend can also be containerized or hosted separately; below focuses on the API container. Adapt paths if your project structure changes.

### 1) Prerequisites
- Azure subscription (can use free trial). You will create: Resource Group, Azure Container Registry (ACR), Azure App Service (Linux, Web App for Containers) or Azure Container Apps. App Service Basic B1 is low cost; Container Apps has a generous free consumption tier.
- GitHub repository with Actions enabled (free public or free private minutes depending on account).
- Dockerfile at e-learning-server/e-learning-server/Dockerfile (adjust if you keep a different path). Ensure it builds a production-ready image.

### 2) Azure Resources to Create (once)
1. Resource Group: rg-elearning (example).
2. Container Registry (ACR): acrelearning (Basic SKU is fine).
3. Web App for Containers (Linux) or Container App:
   - If Web App: name api-elearning, Linux, choose "Docker"; point to your ACR image later.
   - If Container App: create an environment, then an app targeting ACR image.
4. Azure SQL (if not already): create server + database; note the full connection string.
5. (Optional but recommended) Key Vault for secrets; or store secrets as App Settings.

### 3) Required App Settings (in Azure)
Set these on the Web App or Container App:
- ConnectionStrings__DefaultConnection = your Azure SQL connection string
- Bunny:LibraryId, Bunny:APIKey, etc.
- Jwt:Key, Jwt:Issuer, Jwt:Audience
- ASPNETCORE_ENVIRONMENT = Production

For Container Apps, use Secrets + Environment Variables mapping.

### 4) GitHub Secrets to Add
In GitHub repo Settings → Secrets and variables → Actions:
- AZURE_CREDENTIALS: JSON from service principal creation (below).
- AZURE_CONTAINER_REGISTRY = acrelearning.azurecr.io
- AZURE_REGISTRY_USERNAME = from az acr credential show
- AZURE_REGISTRY_PASSWORD = from az acr credential show
- AZURE_WEBAPP_NAME = api-elearning (if using App Service)
- AZURE_RESOURCE_GROUP = rg-elearning
- AZURE_SQL_CONNECTION_STRING = full ADO.NET conn string
- BUNNY_API_KEY, BUNNY_LIBRARY_ID, JWT_KEY, JWT_ISSUER, JWT_AUDIENCE

### 5) Create Service Principal for GitHub Actions
Run locally (requires Azure CLI):
```
az ad sp create-for-rbac \
  --name elearning-cicd \
  --role contributor \
  --scopes /subscriptions/<SUB_ID>/resourceGroups/rg-elearning \
  --sdk-auth
```
Copy the JSON output into AZURE_CREDENTIALS GitHub secret.

### 6) Dockerfile (API) Example
Place at e-learning-server/e-learning-server/Dockerfile:
```
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore e-learning-server.sln
RUN dotnet publish e-learning-server/e-learning-server.csproj -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "e-learning-server.dll"]
```

### 7) GitHub Actions Workflow (Docker → ACR → App Service)
Create .github/workflows/api-docker-azure.yml:
```yaml
name: API CI/CD to Azure (Docker)

on:
  push:
    branches: [ main ]
    paths:
      - "e-learning-server/**"
      - ".github/workflows/api-docker-azure.yml"
  workflow_dispatch:

env:
  IMAGE_NAME: api-elearning
  REGISTRY: ${{ secrets.AZURE_CONTAINER_REGISTRY }}
  WEBAPP_NAME: ${{ secrets.AZURE_WEBAPP_NAME }}
  RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to ACR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.AZURE_REGISTRY_USERNAME }}
          password: ${{ secrets.AZURE_REGISTRY_PASSWORD }}

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          context: ./e-learning-server
          file: ./e-learning-server/e-learning-server/Dockerfile
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Web App (Container)
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.WEBAPP_NAME }}
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

If using Container Apps instead of App Service, replace the deploy step with Azure CLI:
```
- name: Deploy to Container App
  run: |
    az containerapp update \
      --name api-elearning \
      --resource-group $RESOURCE_GROUP \
      --image $REGISTRY/$IMAGE_NAME:latest
```

### 8) Frontend (Docker, optional)
If you want to containerize the frontend and host on App Service:
- Create Dockerfile under e-learning-web/Dockerfile (build then serve via nginx).
- Create another workflow similar to above, tagging e.g., frontend-elearning and a separate Web App (or Container App).

If you prefer Azure Static Web Apps (often cheaper), use the Static Web Apps workflow (non-Docker) instead of containerizing.

### 9) Environment Variables for the API Container
In App Service or Container App, set:
- ConnectionStrings__DefaultConnection
- Bunny:LibraryId, Bunny:APIKey, etc.
- Jwt:Key, Jwt:Issuer, Jwt:Audience
- ASPNETCORE_ENVIRONMENT=Production

### 10) Database Migrations
Option A: run once manually:
```
az webapp ssh --name api-elearning --resource-group rg-elearning
cd /app
dotnet ef database update
```

Option B: separate GitHub Action (manual trigger) using the same image or using dotnet-ef with the connection string from secrets. Keep migrations out of the main deploy unless you want it automatic.

### 11) Local Test Before Push
```
cd e-learning-server
dotnet build
dotnet test   # if tests exist
dotnet publish e-learning-server/e-learning-server.csproj -c Release -o publish
docker build -t local/api-elearning -f e-learning-server/e-learning-server/Dockerfile .
docker run -p 8080:8080 local/api-elearning
```

### 12) Costs & Free Tier Tips
- Use Container Apps consumption to minimize cost; or App Service B1 and stop when not in use.
- Keep ACR Basic (lowest tier) or use Docker Hub if you prefer (adjust workflow login and image tags).
- GitHub Actions: public repos are free; private repos have a minutes quota—keep builds efficient (single job, cache npm/dotnet if desired).

### 13) Troubleshooting
- If deploy fails: check GitHub Actions logs first, then Azure Deployment Center logs (App Service) or Container App revision logs.
- If container will not start: check WEBSITES_PORT (App Service sometimes needs it set to 8080), and ensure ASPNETCORE_URLS=http://+:8080 in Dockerfile.
- CORS: set allowed origins for your frontend domain in the API if needed.

### 14) Next Steps / Variations
- Add staging slot (App Service) or a staging revision (Container Apps) and swap.
- Move secrets into Azure Key Vault and reference them in App Service or Container Apps.
- Add a frontend workflow (Static Web Apps or container) pointing to VITE_API_URL of your API.
