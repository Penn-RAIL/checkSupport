# CheckSupport

![Alt text](CS_LOGO.png)

A command-line tool for suggesting and filling reporting checklists for research manuscripts using local language models via Ollama.

## Installation

```bash
# Clone the repository
git clone <repository-url> checkSupport
cd checkSupport

# Run setup
./checksupport.sh setup
```

The setup command will:
- Create a Python virtual environment
- Install Python dependencies
- Install Ollama (if not present)
- Pull the default model (mistral:instruct)
- Install the CheckSupport CLI

### Setup Options

```bash
# Install with a different model
./checksupport.sh setup -m llama3.1:8b-instruct

# Skip model download
./checksupport.sh setup --skip-model

# Force reinstallation
./checksupport.sh setup -f

# Check status
./checksupport.sh status
```

## Usage

### Environment Management

```bash
# Activate virtual environment
source checksupport/bin/activate

# Start Ollama service
./checksupport.sh start

# Stop Ollama service
./checksupport.sh stop

# Restart Ollama service
./checksupport.sh restart

# Check status
./checksupport.sh status
```

### Suggest a Checklist

Analyzes a manuscript and suggests the most appropriate reporting checklist.

```bash
checksupport suggest manuscript.pdf
checksupport suggest manuscript.pdf --model mistral:instruct
```

Supports `.pdf`, `.docx`, and `.txt` files.

### Fill a Checklist

Fills a checklist based on manuscript content and generates a PDF report.

```bash
checksupport fill --checklist checklist.pdf --manuscript paper.pdf --output report.pdf
checksupport fill --checklist checklist.txt --manuscript study.docx --output report.pdf --model llama3.1:8b-instruct
```

### Model Management

```bash
# Pull a model
./checksupport.sh pull-model mistral:instruct

# List models
./checksupport.sh list-models
```

## Commands

### Environment Management
- `./checksupport.sh setup` - Complete environment setup
- `./checksupport.sh start` - Start Ollama service
- `./checksupport.sh stop` - Stop Ollama service
- `./checksupport.sh restart` - Restart Ollama service
- `./checksupport.sh status` - Check environment status
- `./checksupport.sh uninstall` - Remove environment and Ollama
- `./checksupport.sh update` - Update environment and dependencies

### CLI Commands
- `checksupport suggest <manuscript>` - Suggest appropriate checklist
- `checksupport fill --checklist <checklist> --manuscript <manuscript> --output <output>` - Fill checklist

### Model Management
- `./checksupport.sh pull-model <model>` - Pull specific Ollama model
- `./checksupport.sh list-models` - List installed models

## Supported Formats

- **Manuscript files**: PDF, DOCX, TXT
- **Checklist files**: PDF, DOCX, TXT
- **Checklist types**: PRISMA, STARD, CONSORT, custom formats 
