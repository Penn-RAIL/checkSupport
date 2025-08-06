#!/bin/bash

# CheckSupport - Environment Activation Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Activating CheckSupport environment..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're already in a virtual environment
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}[WARNING]${NC} Already in virtual environment: $VIRTUAL_ENV"
else
    # Try to activate virtual environment
    if [ -f "checksupport/bin/activate" ]; then
        source checksupport/bin/activate
        echo -e "${GREEN}[SUCCESS]${NC} Virtual environment activated"
    elif [ -f "checksupport/Scripts/activate" ]; then
        source checksupport/Scripts/activate
        echo -e "${GREEN}[SUCCESS]${NC} Virtual environment activated"
    else
        echo -e "${YELLOW}[WARNING]${NC} Virtual environment not found, using system Python"
        # Check if required packages are available
        if ! python -c "import PyPDF2, docx, requests" 2>/dev/null; then
            echo -e "${RED}[ERROR]${NC} Required packages not found. Please install them:"
            echo "  pip install PyPDF2 python-docx requests"
            exit 1
        fi
    fi
fi

# Check if Ollama is installed
if ! command_exists ollama; then
    echo -e "${RED}[ERROR]${NC} Ollama is not installed. Please install it first:"
    echo "  ./check-support.sh install"
    exit 1
fi

# Start Ollama if not running
if ! pgrep -f "ollama serve" > /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Starting Ollama service..."
    ollama serve &
    OLLAMA_PID=$!
    echo $OLLAMA_PID > .ollama.pid
    sleep 3
    
    # Check if Ollama started successfully
    if ! pgrep -f "ollama serve" > /dev/null; then
        echo -e "${RED}[ERROR]${NC} Failed to start Ollama service"
        exit 1
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Ollama service started (PID: $OLLAMA_PID)"
else
    echo -e "${GREEN}[SUCCESS]${NC} Ollama service is already running"
fi

# Test Ollama connection
echo -e "${BLUE}[INFO]${NC} Testing Ollama connection..."
if ollama list >/dev/null 2>&1; then
    echo -e "${GREEN}[SUCCESS]${NC} Ollama is responding"
else
    echo -e "${RED}[ERROR]${NC} Ollama is not responding properly"
    exit 1
fi

echo -e "${GREEN}[SUCCESS]${NC} CheckSupport environment is ready!"
echo -e "${BLUE}[INFO]${NC} Available CLI commands:"
echo "  checksupport suggest <manuscript.pdf>"
echo "  checksupport fill --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo "  fill-checklist --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo "  suggest-checklist <manuscript.pdf>"
echo ""
echo -e "${BLUE}[INFO]${NC} To deactivate: deactivate"
echo -e "${BLUE}[INFO]${NC} To stop Ollama: ./stop_ollama.sh"
