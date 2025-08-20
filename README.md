# CheckSupport - A CLI Tool

![Alt text](CS_LOGO.png)

A command-line tool to suggest and fill reporting checklists for research manuscripts using local LLMs via Ollama.

## Installation

**One-Command Setup:**

```bash
# Clone the repository
git clone <your-repo-url> checkSupport
cd checkSupport

# Run the complete setup (installs Python environment, Ollama, dependencies, and models)
./checksupport.sh setup
```

This single command will:
- Create a Python virtual environment
- Install all Python dependencies
- Install Ollama (if not already installed)
- Pull the default model (`llama3.1:8b-instruct-q8_0`)
- Install the CheckSupport CLI tools
- Start the Ollama service

**Alternative Setup Options:**

```bash
# Install with a different model
./checksupport.sh setup -m llama3.1:8b-instruct-q8_0

# Install with a smaller model (if you have memory constraints)
./checksupport.sh setup -m phi3:mini

# Skip model download (install later manually)
./checksupport.sh setup --skip-model

# Force reinstallation
./checksupport.sh setup -f

# Check installation status
./checksupport.sh status

# Test the installation
./checksupport.sh test
```

## Usage

After running the setup, your CheckSupport environment is ready to use. The Ollama service will be running automatically.

### Environment Management

```bash
# Start the environment (activate venv + start Ollama)
./checksupport.sh start

# Stop Ollama service
./checksupport.sh stop

# Activate virtual environment only
./checksupport.sh activate

# Deactivate environment and stop services
./checksupport.sh deactivate

# Check environment status
./checksupport.sh status

# Test environment functionality
./checksupport.sh test
```

### Suggest a Checklist

Analyzes a manuscript and suggests the most appropriate reporting checklist (CONSORT, PRISMA, STARD, DEAL).

```bash
# Using the consolidated script
./checksupport.sh suggest /path/to/your/manuscript.pdf 

# Using the CLI directly
checksupport suggest /path/to/your/manuscript.pdf 

# Specifying a different Ollama model
./checksupport.sh suggest /path/to/your/manuscript.pdf --model mistral:instruct 
# Output: Suggested checklist: PRISMA 
```

*   Supports `.pdf`, `.docx`, and `.txt` manuscript files.
*   The `--model` argument specifies the Ollama model name (defaults to `llama3.1:8b-instruct-q8_0`).

### Fill a Checklist

Fills a custom checklist based on the content of a manuscript and generates a PDF report. The checklist can be provided as a PDF, DOCX, or TXT file containing the checklist items.

```bash
# Using the consolidated script
./checksupport.sh fill --checklist ./files/prismaChecklist.pdf --manuscript paper.docx --output filled_prisma_report.pdf

# Using the CLI directly
checksupport fill --checklist ./files/prismaChecklist.pdf --manuscript paper.docx --output filled_prisma_report.pdf

# Specifying a different Ollama model
./checksupport.sh fill --checklist consort_checklist.txt --manuscript study.pdf --output consort_report.pdf --model gemma:7b-it
# Output: Checklist successfully generated: consort_report.pdf
```

*   `--checklist`: Path to the checklist file (.pdf, .docx, .txt) containing the checklist items to be filled
*   `--manuscript`: Path to the manuscript file (.pdf, .docx, .txt) to analyze
*   `--output`: Path for the generated PDF report (defaults to `filled_checklist.pdf`)
*   `--model`: Optional Ollama model name to use (defaults to `llama3.1:8b-instruct-q8_0`)

### Model Management

```bash
# Pull a specific model
./checksupport.sh pull-model llama3.1:8b-instruct-q8_0

# List installed models
./checksupport.sh list-models
```

### Available Commands

**Environment Management:**
- `./checksupport.sh setup` - Complete environment setup
- `./checksupport.sh start` - Start environment (activate venv + start Ollama)
- `./checksupport.sh stop` - Stop Ollama service
- `./checksupport.sh activate` - Activate virtual environment only
- `./checksupport.sh deactivate` - Deactivate environment and stop services
- `./checksupport.sh status` - Check environment status
- `./checksupport.sh test` - Test environment functionality
- `./checksupport.sh clean` - Remove environment and Ollama installation
- `./checksupport.sh update` - Update environment and dependencies

**CLI Commands:**
- `./checksupport.sh suggest <manuscript>` - Suggest appropriate checklist
- `./checksupport.sh fill --checklist <checklist> --manuscript <manuscript> --output <output>` - Fill checklist
- `checksupport suggest <manuscript>` - Direct CLI suggest command
- `checksupport fill --checklist <checklist> --manuscript <manuscript> --output <output>` - Direct CLI fill command

**Model Management:**
- `./checksupport.sh pull-model <model>` - Pull specific Ollama model
- `./checksupport.sh list-models` - List installed models

The script automatically detects and processes different checklist formats:
- **PRISMA**: For systematic reviews and meta-analyses
- **STARD**: For diagnostic accuracy studies  
- **CONSORT**: For randomized controlled trials
- **Custom formats**: With `::` separators for item instructions
- **Generic**: Automatically parsed checklist structures

## Management Commands

```bash
# Start Ollama service (if not running)
./check-support.sh start

# Stop Ollama service
./check-support.sh stop

# Restart Ollama service
./check-support.sh restart

# Check system status
./check-support.sh status

# Test the installation
./check-support.sh test

# Clean installation (removes everything)
./check-support.sh clean
```

## Scripts

*   `suggest_checklist.py`: Suggests a checklist based on manuscript content using Ollama.
*   `fill_checklist.py`: Fills a custom checklist using manuscript content and Ollama, generating a PDF report.
*   `templates.py`: Contains the structure (item headings) for the supported checklists used by the suggestion feature.
*   `view_sample_files.py`: Utility script to view the content of sample files for testing. 
