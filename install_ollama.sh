#!/bin/bash

# CheckSupport - Environment Setup & Ollama CLI Installation Tool
# A command-line tool to create a complete isolated environment for CheckSupport

set -e  # Exit on any error

# Version and metadata
VERSION="2.0.0"
AUTHOR="CheckSupport Team"
DESCRIPTION="Complete environment setup and Ollama installation tool for CheckSupport CLI"

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
VENV_NAME="checksupport"
PYTHON_VERSION="3.11"
SKIP_VENV=false
SKIP_GIT=false

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
CheckSupport Environment Setup v${VERSION}

${DESCRIPTION}

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    install          Create environment and install CheckSupport (default)
    status           Check environment and Ollama status
    start            Start CheckSupport environment
    stop             Stop CheckSupport environment
    restart          Restart CheckSupport environment
    test             Test environment and Ollama functionality
    clean            Remove environment and Ollama installation
    update           Update environment and dependencies
    help             Show this help message

OPTIONS:
    -m, --model MODEL     Specify model to pull (default: ${DEFAULT_MODEL})
    -v, --verbose         Enable verbose output
    -f, --force           Force reinstallation
    --skip-model          Skip model download
    --skip-deps           Skip Python dependencies installation
    --skip-venv           Skip virtual environment creation
    --skip-git            Skip git repository setup
    --venv-name NAME      Virtual environment name (default: ${VENV_NAME})
    --python-version VER  Python version to use (default: ${PYTHON_VERSION})
    --version             Show version information
    -h, --help            Show this help message

EXAMPLES:
    $0 install                    # Create environment with default settings
    $0 install -m mistral:instruct  # Install with specific model
    $0 status                    # Check environment status
    $0 start                     # Start CheckSupport environment
    $0 test                      # Test environment functionality

AUTHOR: ${AUTHOR}
EOF
}

# Function to show version
show_version() {
    echo "CheckSupport Environment Setup v${VERSION}"
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

# Function to check Python installation
check_python() {
    print_status "Checking Python installation..."
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3.8 or higher."
        print_status "Visit https://python.org for installation instructions."
        exit 1
    fi
    
    # Check Python version
    PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    print_success "Python $PYTHON_VER found"
    
    # Check if version is sufficient
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
        print_success "Python version is compatible"
    else
        print_error "Python 3.8 or higher is required"
        exit 1
    fi
}

# Function to check pip installation
check_pip() {
    print_status "Checking pip installation..."
    
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed. Please install pip."
        exit 1
    fi
    
    print_success "pip3 found"
}

# Function to create virtual environment
create_virtual_environment() {
    if [ "$SKIP_VENV" = true ]; then
        print_warning "Skipping virtual environment creation"
        return 0
    fi
    
    print_status "Creating virtual environment: $VENV_NAME"
    
    # Check if virtual environment already exists
    if [ -d "$VENV_NAME" ]; then
        if [ "$FORCE_INSTALL" = true ]; then
            print_warning "Removing existing virtual environment"
            rm -rf "$VENV_NAME"
        else
            print_warning "Virtual environment '$VENV_NAME' already exists"
            print_status "Use --force to recreate it"
            return 0
        fi
    fi
    
    # Create virtual environment
    if python3 -m venv "$VENV_NAME"; then
        print_success "Virtual environment created successfully"
    else
        print_error "Failed to create virtual environment"
        exit 1
    fi
}

# Function to activate virtual environment
activate_virtual_environment() {
    print_verbose "Activating virtual environment: $VENV_NAME"
    
    if [ -f "$VENV_NAME/bin/activate" ]; then
        source "$VENV_NAME/bin/activate"
        print_success "Virtual environment activated"
    elif [ -f "$VENV_NAME/Scripts/activate" ]; then
        source "$VENV_NAME/Scripts/activate"
        print_success "Virtual environment activated"
    else
        print_error "Could not find virtual environment activation script"
        exit 1
    fi
}

# Function to install Python dependencies
install_python_dependencies() {
    if [ "$SKIP_PYTHON_DEPS" = true ]; then
        print_warning "Skipping Python dependencies installation"
        return 0
    fi
    
    print_status "Installing Python dependencies..."
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install dependencies from requirements.txt
    if [ -f "requirements.txt" ]; then
        if pip install -r requirements.txt; then
            print_success "Python dependencies installed successfully"
        else
            print_error "Failed to install Python dependencies"
            exit 1
        fi
    else
        print_warning "requirements.txt not found. Installing basic dependencies..."
        
        # Install basic dependencies if requirements.txt doesn't exist
        pip install requests pypdf2 python-docx reportlab
        print_success "Basic dependencies installed"
    fi
    
    # Install CheckSupport package in development mode
    print_status "Installing CheckSupport CLI package..."
    if pip install -e .; then
        print_success "CheckSupport CLI package installed successfully"
    else
        print_warning "Failed to install CheckSupport CLI package in development mode"
        print_status "You can still run the scripts directly: python checksupport/fill_checklist.py"
    fi
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

# Function to create environment scripts
create_environment_scripts() {
    print_status "Creating environment scripts..."
    
    # Activation script
    cat > activate_env.sh << 'EOF'
#!/bin/bash

# CheckSupport - Environment Activation Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Activating CheckSupport environment..."

# Activate virtual environment
if [ -f "checksupport/bin/activate" ]; then
    source checksupport/bin/activate
    echo -e "${GREEN}[SUCCESS]${NC} Virtual environment activated"
elif [ -f "checksupport/Scripts/activate" ]; then
    source checksupport/Scripts/activate
    echo -e "${GREEN}[SUCCESS]${NC} Virtual environment activated"
else
    echo -e "${BLUE}[INFO]${NC} Virtual environment not found, using system Python"
fi

# Start Ollama if not running
if ! pgrep -f "ollama serve" > /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Starting Ollama service..."
    ollama serve &
    echo $! > .ollama.pid
    sleep 3
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
EOF

    # Start script
    cat > start_checklist.sh << 'EOF'
#!/bin/bash

# CheckSupport - Start Script
# This script activates the environment and starts CheckSupport tools

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Starting CheckSupport environment..."

# Activate virtual environment
if [ -f "checksupport/bin/activate" ]; then
    source checksupport/bin/activate
elif [ -f "checksupport/Scripts/activate" ]; then
    source checksupport/Scripts/activate
fi

# Check if Ollama is running
if ! pgrep -f "ollama serve" > /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Starting Ollama service..."
    ollama serve &
    echo $! > .ollama.pid
    sleep 3
fi

echo -e "${GREEN}[SUCCESS]${NC} CheckSupport is ready to use!"
echo -e "${BLUE}[INFO]${NC} Available CLI commands:"
echo "  checksupport suggest <manuscript.pdf>"
echo "  checksupport fill --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo "  fill-checklist --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
echo "  suggest-checklist <manuscript.pdf>"
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

    # Deactivate script
    cat > deactivate_env.sh << 'EOF'
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
EOF

    chmod +x activate_env.sh start_checklist.sh stop_ollama.sh deactivate_env.sh
    print_success "Created environment scripts"
}

# Function to show status
show_status() {
    echo ""
    echo "=========================================="
    echo "CheckSupport Environment Status"
    echo "=========================================="
    echo ""
    
    # Check virtual environment
    if [ -d "$VENV_NAME" ]; then
        echo -e "${GREEN}✓${NC} Virtual environment exists: $VENV_NAME"
    else
        echo -e "${RED}✗${NC} Virtual environment not found: $VENV_NAME"
    fi
    
    # Check Python
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}✓${NC} Python is installed"
        echo "  Version: $(python3 --version)"
    else
        echo -e "${RED}✗${NC} Python is not installed"
    fi
    
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

# Function to test environment
test_environment() {
    print_status "Testing CheckSupport environment..."
    
    # Test Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found"
        return 1
    fi
    
    # Test virtual environment
    if [ ! -d "$VENV_NAME" ]; then
        print_error "Virtual environment not found"
        return 1
    fi
    
    # Test Ollama
    if ! command -v ollama &> /dev/null; then
        print_error "Ollama not found"
        return 1
    fi
    
    # Test service
    if ! pgrep -f "ollama serve" > /dev/null; then
        print_warning "Ollama service not running, starting it..."
        start_ollama_service
    fi
    
    # Test Ollama functionality
    if ollama list &> /dev/null; then
        print_success "Environment is working correctly"
        
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

# Function to clean environment
clean_environment() {
    print_warning "This will remove the entire CheckSupport environment and Ollama. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Cleaning CheckSupport environment..."
        
        # Stop service
        stop_ollama_service
        
        # Remove virtual environment
        if [ -d "$VENV_NAME" ]; then
            rm -rf "$VENV_NAME"
            print_success "Virtual environment removed"
        fi
        
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
        
        # Remove environment scripts
        rm -f activate_env.sh start_checklist.sh stop_ollama.sh deactivate_env.sh
        
        print_success "CheckSupport environment cleaned"
    else
        print_status "Clean operation cancelled"
    fi
}

# Function to update environment
update_environment() {
    print_status "Updating CheckSupport environment..."
    
    # Update Python dependencies
    if [ -d "$VENV_NAME" ]; then
        activate_virtual_environment
        pip install --upgrade pip
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt --upgrade
        fi
        print_success "Python dependencies updated"
    fi
    
    # Update Ollama
    if command -v ollama &> /dev/null; then
        print_status "Updating Ollama..."
        case $OS in
            "macos")
                brew upgrade ollama
                ;;
            "linux"|"windows")
                curl -fsSL https://ollama.com/install.sh | sh
                ;;
        esac
        print_success "Ollama updated"
    fi
    
    print_success "Environment updated successfully"
}

# Function to display completion message
display_completion() {
    echo ""
    echo "=========================================="
    echo "CheckSupport - Environment Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Environment created successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Activate the environment: source activate_env.sh"
    echo "2. Or start the environment: ./start_checklist.sh"
    echo "3. Test the installation: ./install_ollama.sh test"
    echo "4. Deactivate when done: ./deactivate_env.sh"
    echo ""
    echo "Available CLI commands:"
    echo "- checksupport suggest <manuscript>"
    echo "- checksupport fill --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
    echo "- fill-checklist --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
    echo "- suggest-checklist <manuscript>"
    echo ""
    echo "Legacy commands (still work):"
    echo "- python checksupport/suggest_checklist.py <manuscript>"
    echo "- python checksupport/fill_checklist.py --checklist <checklist> --manuscript <manuscript> --output <output.pdf>"
    echo ""
    echo "Environment scripts:"
    echo "- activate_env.sh: Activate virtual environment and start Ollama"
    echo "- start_checklist.sh: Start CheckSupport environment"
    echo "- stop_ollama.sh: Stop Ollama service"
    echo "- deactivate_env.sh: Deactivate environment and stop services"
    echo ""
    echo "For more information, see README.md"
    echo ""
}

# Function to handle installation
install_environment() {
    print_status "Starting CheckSupport environment setup..."
    
    # Detect OS
    detect_os
    
    # Check Python and pip
    check_python
    check_pip
    
    # Create virtual environment
    create_virtual_environment
    
    # Activate virtual environment
    activate_virtual_environment
    
    # Install Python dependencies
    install_python_dependencies
    
    # Install Ollama if not already installed
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
    
    # Create environment scripts
    create_environment_scripts
    
    # Display completion message
    display_completion
}

# Parse command line arguments
parse_args() {
    COMMAND="install"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|status|start|stop|restart|test|clean|update|help)
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
            --skip-venv)
                SKIP_VENV=true
                shift
                ;;
            --skip-git)
                SKIP_GIT=true
                shift
                ;;
            --venv-name)
                VENV_NAME="$2"
                shift 2
                ;;
            --python-version)
                PYTHON_VERSION="$2"
                shift 2
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
            install_environment
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
            test_environment
            ;;
        clean)
            clean_environment
            ;;
        update)
            update_environment
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