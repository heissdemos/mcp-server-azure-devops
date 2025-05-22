FROM node:18-slim

WORKDIR /app

# Kopiere package.json und package-lock.json
COPY package*.json ./

# Installiere Abhängigkeiten
RUN npm ci

# Kopiere den Quellcode
COPY . .

# Baue das Projekt
RUN npm run build

# Standard-Umgebungsvariablen (diese sollten bei Container-Start überschrieben werden)
ENV AZURE_DEVOPS_ORG_URL=""
ENV AZURE_DEVOPS_AUTH_METHOD="azure-identity"
ENV AZURE_DEVOPS_PAT=""
ENV AZURE_DEVOPS_DEFAULT_PROJECT=""

# Führe den MCP-Server aus
CMD ["node", "dist/index.js"]