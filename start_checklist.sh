#!/bin/bash

# CheckSupport - Start Script
# This script activates the environment and starts CheckSupport tools

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Starting CheckSupport environment..."

# Check if activate_env.sh exists and use it
if [ -f "activate_env.sh" ]; then
    source activate_env.sh
else
    echo -e "${RED}[ERROR]${NC} activate_env.sh not found"
    exit 1
fi

echo -e "${GREEN}[SUCCESS]${NC} CheckSupport is ready to use!"
echo -e "${BLUE}[INFO]${NC} Available CLI commands:"
echo "  checksupport suggest <manuscript.pdf>"
echo "  checksupport fill --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo "  fill-checklist --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo "  suggest-checklist <manuscript.pdf>"
echo ""
echo -e "${BLUE}[INFO]${NC} To stop Ollama service: ./stop_ollama.sh"
