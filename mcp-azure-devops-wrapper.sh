#!/bin/bash

# Azure DevOps MCP Server Wrapper Script
# This script allows Claude MCP to connect to the Azure DevOps MCP server running in Docker

set -e

# Configuration
CONTAINER_NAME="azure-devops-mcp"
DOCKER_IMAGE="mcp-server-azure-devops-azure-devops-mcp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to start container if not running
ensure_container_running() {
    if ! container_exists; then
        log_info "Container $CONTAINER_NAME does not exist. Creating and starting..."
        
        # Check if env file exists
        if [ ! -f "$ENV_FILE" ]; then
            log_error "Environment file not found: $ENV_FILE"
            log_error "Please create .env file with your Azure DevOps configuration."
            exit 1
        fi
        
        # Start with docker-compose
        cd "$SCRIPT_DIR"
        docker compose up -d
    elif ! container_running; then
        log_info "Container $CONTAINER_NAME exists but is not running. Starting..."
        docker start "$CONTAINER_NAME"
    else
        log_info "Container $CONTAINER_NAME is already running."
    fi
    
    # Wait a moment for container to be ready
    sleep 2
    
    # Verify container is healthy
    if ! container_running; then
        log_error "Failed to start container $CONTAINER_NAME"
        exit 1
    fi
}

# Function to stop container
stop_container() {
    if container_running; then
        log_info "Stopping container $CONTAINER_NAME..."
        docker stop "$CONTAINER_NAME"
    else
        log_warn "Container $CONTAINER_NAME is not running."
    fi
}

# Function to connect to the MCP server
connect_mcp() {
    log_info "Connecting to Azure DevOps MCP Server..."
    
    # Execute the MCP server in the container
    exec docker exec -i "$CONTAINER_NAME" node dist/index.js
}

# Function to show container logs
show_logs() {
    if container_exists; then
        log_info "Showing logs for container $CONTAINER_NAME..."
        docker logs "$CONTAINER_NAME" --tail 50
    else
        log_error "Container $CONTAINER_NAME does not exist."
        exit 1
    fi
}

# Function to show container status
show_status() {
    log_info "Azure DevOps MCP Server Status:"
    echo
    
    if container_exists; then
        if container_running; then
            echo -e "${GREEN}✓${NC} Container is running"
            echo "Container ID: $(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.ID}}")"
            echo "Uptime: $(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Status}}")"
        else
            echo -e "${YELLOW}!${NC} Container exists but is stopped"
        fi
    else
        echo -e "${RED}✗${NC} Container does not exist"
    fi
    
    echo
    if [ -f "$ENV_FILE" ]; then
        echo -e "${GREEN}✓${NC} Environment file found: $ENV_FILE"
        echo "Configuration:"
        grep -E "^AZURE_DEVOPS_" "$ENV_FILE" | while read -r line; do
            key=$(echo "$line" | cut -d'=' -f1)
            if [[ "$key" == "AZURE_DEVOPS_PAT" ]]; then
                echo "  $key=***HIDDEN***"
            else
                echo "  $line"
            fi
        done
    else
        echo -e "${RED}✗${NC} Environment file not found: $ENV_FILE"
    fi
}

# Main function
main() {
    case "${1:-connect}" in
        "connect"|"")
            check_docker
            ensure_container_running
            connect_mcp
            ;;
        "start")
            check_docker
            ensure_container_running
            log_info "Container started successfully."
            ;;
        "stop")
            check_docker
            stop_container
            ;;
        "restart")
            check_docker
            stop_container
            sleep 2
            ensure_container_running
            log_info "Container restarted successfully."
            ;;
        "logs")
            check_docker
            show_logs
            ;;
        "status")
            check_docker
            show_status
            ;;
        "help"|"-h"|"--help")
            echo "Azure DevOps MCP Server Wrapper"
            echo
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  connect  (default) - Connect to the MCP server (starts container if needed)"
            echo "  start    - Start the container"
            echo "  stop     - Stop the container"
            echo "  restart  - Restart the container"
            echo "  logs     - Show container logs"
            echo "  status   - Show container and configuration status"
            echo "  help     - Show this help message"
            echo
            echo "Environment:"
            echo "  The script looks for .env file in: $ENV_FILE"
            echo
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"