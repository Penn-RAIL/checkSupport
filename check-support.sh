#!/bin/bash

# CheckSupport - Ollama CLI Installation Tool
# A command-line tool to install and configure Ollama for the CheckSupport CLI tool

set -e  # Exit on any error

# Version and metadata
VERSION="1.0.0"
AUTHOR="CheckSupport Team"
DESCRIPTION="Ollama installation and configuration tool for CheckSupport CLI"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
DEFAULT_MODEL="llama3.1:8b-instruct-q8_0"
VERBOSE=false
SKIP_MODEL_PULL=false
SKIP_PYTHON_DEPS=false
FORCE_INSTALL=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Function to display help
show_help() {
    cat << EOF
CheckSupport Ollama Installer v${VERSION}

${DESCRIPTION}

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    install          Install Ollama and configure CheckSupport (default)
    status           Check Ollama installation status
    start            Start Ollama service
    stop             Stop Ollama service
    restart          Restart Ollama service
    test             Test Ollama functionality
    clean            Remove Ollama installation and data
    help             Show this help message

OPTIONS:
    -m, --model MODEL     Specify model to pull (default: ${DEFAULT_MODEL})
    -v, --verbose         Enable verbose output
    -f, --force           Force reinstallation
    --skip-model          Skip model download
    --skip-deps           Skip Python dependencies installation
    --version             Show version information
    -h, --help            Show this help message

EXAMPLES:
    $0 install                    # Install with default settings
    $0 install -m mistral:instruct  # Install with specific model
    $0 status                    # Check installation status
    $0 start                     # Start Ollama service
    $0 test                      # Test Ollama functionality

AUTHOR: ${AUTHOR}
EOF
}

# Function to show version
show_version() {
    echo "CheckSupport Ollama Installer v${VERSION}"
    echo "Author: ${AUTHOR}"
    echo "Description: ${DESCRIPTION}"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_verbose "Detected OS: $OS"
}

# Function to check if Ollama is already installed
check_ollama_installed() {
    if command -v ollama &> /dev/null; then
        print_success "Ollama is already installed"
        return 0
    else
        print_status "Ollama not found"
        return 1
    fi
}

# Function to install Ollama on macOS
install_ollama_macos() {
    print_status "Installing Ollama on macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_status "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Ollama using Homebrew
    brew install ollama
    print_success "Ollama installed successfully via Homebrew"
}

# Function to install Ollama on Linux
install_ollama_linux() {
    print_status "Installing Ollama on Linux..."
    
    # Download and install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    
    print_success "Ollama installed successfully"
}

# Function to install Ollama on Windows (WSL)
install_ollama_windows() {
    print_status "Installing Ollama on Windows (WSL)..."
    
    # Check if running in WSL
    if grep -qi microsoft /proc/version; then
        print_status "Detected WSL environment"
        curl -fsSL https://ollama.com/install.sh | sh
        print_success "Ollama installed successfully in WSL"
    else
        print_error "Windows installation detected but not running in WSL"
        print_status "Please install WSL2 and run this script again, or install Ollama manually from https://ollama.com"
        exit 1
    fi
}

# Function to start Ollama service
start_ollama_service() {
    print_status "Starting Ollama service..."
    
    # Check if already running
    if pgrep -f "ollama serve" > /dev/null; then
        print_warning "Ollama service is already running"
        return 0
    fi
    
    # Start Ollama in the background
    ollama serve &
    OLLAMA_PID=$!
    
    # Wait a moment for the service to start
    sleep 3
    
    # Check if Ollama is running
    if pgrep -f "ollama serve" > /dev/null; then
        print_success "Ollama service started successfully (PID: $OLLAMA_PID)"
        echo $OLLAMA_PID > .ollama.pid
    else
        print_error "Failed to start Ollama service"
        exit 1
    fi
}

# Function to stop Ollama service
stop_ollama_service() {
    print_status "Stopping Ollama service..."
    
    if pgrep -f "ollama serve" > /dev/null; then
        pkill -f "ollama serve"
        print_success "Ollama service stopped"
        
        # Remove PID file if it exists
        if [ -f ".ollama.pid" ]; then
            rm .ollama.pid
        fi
    else
        print_warning "Ollama service is not running"
    fi
}

# Function to pull model
pull_model() {
    local model=${1:-$DEFAULT_MODEL}
    print_status "Pulling model: $model"
    
    if ollama pull "$model"; then
        print_success "Model '$model' pulled successfully"
    else
        print_warning "Failed to pull model '$model'. You can pull it manually later with: ollama pull $model"
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if ollama command is available
    if ! command -v ollama &> /dev/null; then
        print_error "Ollama command not found in PATH"
        return 1
    fi
    
    # Check if Ollama service is running
    if ! pgrep -f "ollama serve" > /dev/null; then
        print_warning "Ollama service is not running. Starting it now..."
        start_ollama_service
    else
        print_success "Ollama service is running"
    fi
    
    # Test Ollama connection
    if ollama list &> /dev/null; then
        print_success "Ollama is working correctly"
    else
        print_error "Ollama is not responding properly"
        return 1
    fi
    
    return 0
}

# Function to install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    if [ -f "requirements.txt" ]; then
        if pip install -r requirements.txt; then
            print_success "Python dependencies installed successfully"
        else
            print_warning "Failed to install Python dependencies. Please install them manually: pip install -r requirements.txt"
        fi
    else
        print_warning "requirements.txt not found. Skipping Python dependency installation."
    fi
}

# Function to create convenience scripts
create_convenience_scripts() {
    print_status "Creating convenience scripts..."
    
    # Start script
    cat > start_checklist.sh << 'EOF'
#!/bin/bash

# CheckSupport - Start Script
# This script starts Ollama and runs the CheckSupport tools

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Starting CheckSupport environment..."

# Check if Ollama is running
if ! pgrep -f "ollama serve" > /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Starting Ollama service..."
    ollama serve &
    echo $! > .ollama.pid
    sleep 3
fi

echo -e "${GREEN}[SUCCESS]${NC} CheckSupport is ready to use!"
echo -e "${BLUE}[INFO]${NC} Available commands:"
echo "  python suggest_checklist.py <manuscript.pdf>"
echo "  python fill_checklist.py --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo ""
echo -e "${BLUE}[INFO]${NC} To stop Ollama service: ./stop_ollama.sh"
EOF

    # Stop script
    cat > stop_ollama.sh << 'EOF'
#!/bin/bash

# CheckSupport - Stop Ollama Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Stopping Ollama service..."

# Stop Ollama if running
if pgrep -f "ollama serve" > /dev/null; then
    pkill -f "ollama serve"
    echo -e "${GREEN}[SUCCESS]${NC} Ollama service stopped"
else
    echo -e "${BLUE}[INFO]${NC} Ollama service is not running"
fi

# Remove PID file if it exists
if [ -f ".ollama.pid" ]; then
    rm .ollama.pid
fi
EOF

    chmod +x start_checklist.sh stop_ollama.sh
    print_success "Created convenience scripts"
}

# Function to show status
show_status() {
    echo ""
    echo "=========================================="
    echo "CheckSupport Ollama Status"
    echo "=========================================="
    echo ""
    
    # Check Ollama installation
    if command -v ollama &> /dev/null; then
        echo -e "${GREEN}✓${NC} Ollama is installed"
        echo "  Version: $(ollama --version 2>/dev/null || echo 'Unknown')"
    else
        echo -e "${RED}✗${NC} Ollama is not installed"
    fi
    
    # Check service status
    if pgrep -f "ollama serve" > /dev/null; then
        echo -e "${GREEN}✓${NC} Ollama service is running"
        echo "  PID: $(pgrep -f 'ollama serve')"
    else
        echo -e "${RED}✗${NC} Ollama service is not running"
    fi
    
    # Check models
    echo ""
    echo "Installed models:"
    if ollama list &> /dev/null; then
        ollama list 2>/dev/null || echo "  No models found"
    else
        echo "  Unable to list models (service may not be running)"
    fi
    
    # Check Python dependencies
    echo ""
    if [ -f "requirements.txt" ]; then
        echo -e "${GREEN}✓${NC} requirements.txt found"
    else
        echo -e "${YELLOW}⚠${NC} requirements.txt not found"
    fi
}

# Function to test Ollama
test_ollama() {
    print_status "Testing Ollama functionality..."
    
    # Test basic command
    if ! command -v ollama &> /dev/null; then
        print_error "Ollama command not found"
        return 1
    fi
    
    # Test service
    if ! pgrep -f "ollama serve" > /dev/null; then
        print_warning "Ollama service not running, starting it..."
        start_ollama_service
    fi
    
    # Test list command
    if ollama list &> /dev/null; then
        print_success "Ollama is working correctly"
        
        # Show available models
        echo ""
        print_status "Available models:"
        ollama list 2>/dev/null || echo "  No models found"
        
        return 0
    else
        print_error "Ollama is not responding properly"
        return 1
    fi
}

# Function to clean installation
clean_installation() {
    print_warning "This will remove Ollama and all downloaded models. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Cleaning Ollama installation..."
        
        # Stop service
        stop_ollama_service
        
        # Remove Ollama (platform specific)
        case $OS in
            "macos")
                brew uninstall ollama 2>/dev/null || true
                ;;
            "linux"|"windows")
                sudo rm -rf /usr/local/bin/ollama 2>/dev/null || true
                ;;
        esac
        
        # Remove data directory
        rm -rf ~/.ollama 2>/dev/null || true
        
        # Remove PID file
        rm -f .ollama.pid
        
        print_success "Ollama installation cleaned"
    else
        print_status "Clean operation cancelled"
    fi
}

# Function to display completion message
display_completion() {
    echo ""
    echo "=========================================="
    echo "CheckSupport - Installation Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Start the environment: ./start_checklist.sh"
    echo "2. Test the installation:"
    echo "   python suggest_checklist.py files/test1.pdf"
    echo "3. Stop Ollama when done: ./stop_ollama.sh"
    echo ""
    echo "Available commands:"
    echo "- python suggest_checklist.py <manuscript>"
    echo "- python fill_checklist.py --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
    echo ""
    echo "For more information, see README.md"
    echo ""
}

# Function to handle installation
install_ollama() {
    print_status "Starting Ollama installation..."
    
    # Detect OS
    detect_os
    
    # Check if Ollama is already installed
    if check_ollama_installed && [ "$FORCE_INSTALL" = false ]; then
        print_status "Ollama is already installed, proceeding with verification..."
    else
        # Install Ollama based on OS
        case $OS in
            "macos")
                install_ollama_macos
                ;;
            "linux")
                install_ollama_linux
                ;;
            "windows")
                install_ollama_windows
                ;;
            *)
                print_error "Unsupported OS: $OS"
                exit 1
                ;;
        esac
    fi
    
    # Start Ollama service
    start_ollama_service
    
    # Pull model if not skipped
    if [ "$SKIP_MODEL_PULL" = false ]; then
        pull_model "$DEFAULT_MODEL"
    fi
    
    # Verify installation
    if verify_installation; then
        print_success "Installation completed successfully!"
    else
        print_error "Installation verification failed"
        exit 1
    fi
    
    # Install Python dependencies if not skipped
    if [ "$SKIP_PYTHON_DEPS" = false ]; then
        install_python_deps
    fi
    
    # Create convenience scripts
    create_convenience_scripts
    
    # Display completion message
    display_completion
}

# Parse command line arguments
parse_args() {
    COMMAND="install"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|status|start|stop|restart|test|clean|help)
                COMMAND="$1"
                shift
                ;;
            -m|--model)
                DEFAULT_MODEL="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            --skip-model)
                SKIP_MODEL_PULL=true
                shift
                ;;
            --skip-deps)
                SKIP_PYTHON_DEPS=true
                shift
                ;;
            --version)
                show_version
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Parse arguments
    parse_args "$@"
    
    # Execute command
    case $COMMAND in
        install)
            install_ollama
            ;;
        status)
            show_status
            ;;
        start)
            start_ollama_service
            ;;
        stop)
            stop_ollama_service
            ;;
        restart)
            stop_ollama_service
            sleep 2
            start_ollama_service
            ;;
        test)
            test_ollama
            ;;
        clean)
            clean_installation
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"