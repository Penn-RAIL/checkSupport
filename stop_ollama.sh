#!/bin/bash

# CheckSupport - Stop Ollama Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Stopping Ollama service..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Ollama is installed
if ! command_exists ollama; then
    echo -e "${YELLOW}[WARNING]${NC} Ollama is not installed"
    exit 0
fi

# Stop Ollama if running
if pgrep -f "ollama serve" > /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Found running Ollama process, stopping..."
    
    # Try graceful shutdown first
    pkill -f "ollama serve"
    
    # Wait a moment for graceful shutdown
    sleep 2
    
    # Check if still running and force kill if necessary
    if pgrep -f "ollama serve" > /dev/null; then
        echo -e "${YELLOW}[WARNING]${NC} Graceful shutdown failed, forcing termination..."
        pkill -9 -f "ollama serve"
        sleep 1
    fi
    
    # Final check
    if pgrep -f "ollama serve" > /dev/null; then
        echo -e "${RED}[ERROR]${NC} Failed to stop Ollama service"
        exit 1
    else
        echo -e "${GREEN}[SUCCESS]${NC} Ollama service stopped"
    fi
else
    echo -e "${BLUE}[INFO]${NC} Ollama service is not running"
fi

# Remove PID file if it exists
if [ -f ".ollama.pid" ]; then
    rm .ollama.pid
    echo -e "${BLUE}[INFO]${NC} Removed PID file"
fi

echo -e "${GREEN}[SUCCESS]${NC} Ollama cleanup completed"
