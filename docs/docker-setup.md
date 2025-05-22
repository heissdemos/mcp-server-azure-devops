# Docker Setup für Azure DevOps MCP Server

Diese Anleitung erklärt, wie der Azure DevOps MCP Server in einem Docker-Container ausgeführt werden kann.

## Voraussetzungen

- Docker und Docker Compose installiert
- Azure DevOps Anmeldedaten (je nach Authentifizierungsmethode)

## Schnellstart mit Docker Compose

1. **Erstellen Sie eine `.env`-Datei im Projektverzeichnis mit Ihren Azure DevOps-Anmeldedaten:**

```bash
# Azure DevOps Konfiguration
AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-organization
AZURE_DEVOPS_AUTH_METHOD=pat
AZURE_DEVOPS_PAT=your-personal-access-token
AZURE_DEVOPS_DEFAULT_PROJECT=your-project-name

# Optional: Logging-Konfiguration
LOG_LEVEL=info
```

2. **Starten Sie den Container mit Docker Compose:**

```bash
docker-compose up
```

3. **Für die Ausführung im Hintergrund:**

```bash
docker-compose up -d
```

## Manueller Build und Start

1. **Container bauen:**

```bash
docker build -t azure-devops-mcp .
```

2. **Container starten mit PAT-Authentifizierung:**

```bash
docker run -it \
  -e AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-organization \
  -e AZURE_DEVOPS_AUTH_METHOD=pat \
  -e AZURE_DEVOPS_PAT=your-personal-access-token \
  -e AZURE_DEVOPS_DEFAULT_PROJECT=your-project-name \
  azure-devops-mcp
```

## Authentifizierungsmethoden im Container

### 1. Personal Access Token (PAT)

Dies ist die einfachste Methode für den Container:

```bash
docker run -it \
  -e AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-organization \
  -e AZURE_DEVOPS_AUTH_METHOD=pat \
  -e AZURE_DEVOPS_PAT=your-personal-access-token \
  -e AZURE_DEVOPS_DEFAULT_PROJECT=your-project-name \
  azure-devops-mcp
```

### 2. Azure CLI

Für die Azure CLI-Authentifizierung müssen Sie das Azure CLI-Konfigurationsverzeichnis mounten:

```bash
docker run -it \
  -e AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-organization \
  -e AZURE_DEVOPS_AUTH_METHOD=azure-cli \
  -e AZURE_DEVOPS_DEFAULT_PROJECT=your-project-name \
  -v ${HOME}/.azure:/root/.azure:ro \
  azure-devops-mcp
```

### 3. Azure Identity (Service Principal)

Für Service Principal-Authentifizierung:

```bash
docker run -it \
  -e AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-organization \
  -e AZURE_DEVOPS_AUTH_METHOD=azure-identity \
  -e AZURE_DEVOPS_DEFAULT_PROJECT=your-project-name \
  -e AZURE_TENANT_ID=your-tenant-id \
  -e AZURE_CLIENT_ID=your-client-id \
  -e AZURE_CLIENT_SECRET=your-client-secret \
  azure-devops-mcp
```

## Integration mit Claude/Cursor AI

Um den Docker-Container mit Claude oder Cursor AI zu verwenden, aktualisieren Sie Ihre `.claude-mcp.json` Konfiguration:

```json
{
  "mcpServers": {
    "azureDevOps": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "azure-devops-mcp"],
      "env": {
        "AZURE_DEVOPS_ORG_URL": "https://dev.azure.com/your-organization",
        "AZURE_DEVOPS_AUTH_METHOD": "pat",
        "AZURE_DEVOPS_PAT": "<YOUR_PAT>",
        "AZURE_DEVOPS_DEFAULT_PROJECT": "your-project-name"
      }
    }
  }
}
```

## Sicherheitshinweise

- Speichern Sie keine sensiblen Anmeldedaten (PATs, Client Secrets) im Dockerfile
- Verwenden Sie `.env`-Dateien oder Docker Secrets für Produktionsumgebungen
- Verwenden Sie read-only Volumes, wenn Sie lokale Konfigurationsdateien mounten

## Fehlerbehebung

### Container startet nicht

Überprüfen Sie die Docker-Logs:

```bash
docker logs azure-devops-mcp
```

### Authentifizierungsprobleme

- Stellen Sie sicher, dass die Umgebungsvariablen korrekt gesetzt sind
- Bei PAT-Authentifizierung: Überprüfen Sie, ob das Token gültig ist und die erforderlichen Berechtigungen hat
- Bei Azure CLI: Stellen Sie sicher, dass die gemounteten Konfigurationsdateien gültig sind