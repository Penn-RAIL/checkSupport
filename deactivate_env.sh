#!/bin/bash

# CheckSupport - Environment Deactivation Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Deactivating CheckSupport environment..."

# Stop Ollama service
if pgrep -f "ollama serve" > /dev/null; then
    pkill -f "ollama serve"
    echo -e "${GREEN}[SUCCESS]${NC} Ollama service stopped"
fi

# Remove PID file if it exists
if [ -f ".ollama.pid" ]; then
    rm .ollama.pid
fi

# Deactivate virtual environment
if [ -n "$VIRTUAL_ENV" ]; then
    deactivate
    echo -e "${GREEN}[SUCCESS]${NC} Virtual environment deactivated"
fi

echo -e "${GREEN}[SUCCESS]${NC} CheckSupport environment deactivated"
