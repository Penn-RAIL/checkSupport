# Checklist CLI

A command-line tool to suggest and fill reporting checklists for research manuscripts using local LLMs via Ollama.

## Installation

1.  **Install Ollama:** Follow the instructions on [ollama.com](https://ollama.com/) to download and install Ollama for your operating system.

2.  **Pull an LLM:** Open your terminal and pull a suitable instruction-following model. The current default is `llama3.1:8b-instruct-q8_0`. Examples:
    ```bash
    ollama pull llama3.1:8b-instruct-q8_0
    # or
    ollama pull mistral:instruct 
    # or
    ollama pull gemma:7b-it
    ```
    Make sure the Ollama application/server is running in the background.

3.  **Clone the Repository & Install Dependencies:**
    ```bash
    git clone <your-repo-url> checklist_cli
    cd checklist_cli
    pip install -r requirements.txt 
    # or python -m pip install -r requirements.txt
    ```

## Usage

Make sure the Ollama application is running before executing the scripts.

### Suggest a Checklist

Analyzes a manuscript and suggests the most appropriate reporting checklist (CONSORT, PRISMA, STARD, DEAL).

```bash
# Using the default model (llama3.1:8b-instruct-q8_0)
python suggest_checklist.py /path/to/your/manuscript.pdf 

# Specifying a different Ollama model
python suggest_checklist.py /path/to/your/manuscript.pdf --model mistral:instruct 
# Output: Suggested checklist: PRISMA 
```

*   Supports `.pdf`, `.docx`, and `.txt` manuscript files.
*   The `--model` argument specifies the Ollama model name (defaults to `llama3.1:8b-instruct-q8_0`).

### Fill a Checklist

Fills a specified checklist template based on the content of a manuscript and generates a PDF report.

```bash
# Using the default model (llama3.1:8b-instruct-q8_0)
python fill_checklist.py --template PRISMA --manuscript paper.docx --output filled_prisma_report.pdf

# Specifying a different Ollama model
python fill_checklist.py --template CONSORT --manuscript study.txt --output consort_report.pdf --model gemma:7b-it
# Output: Checklist successfully generated: consort_report.pdf
```

*   `--template`: Choose one of `CONSORT`, `PRISMA`, `STARD`, `DEAL`.
*   `--manuscript`: Path to the `.pdf`, `.docx`, or `.txt` file.
*   `--output`: Path for the generated PDF (defaults to `filled_checklist.pdf`).
*   `--model`: Optional Ollama model name to use (defaults to `llama3.1:8b-instruct-q8_0`).

## Scripts

*   `suggest_checklist.py`: Suggests a checklist based on manuscript content using Ollama.
*   `fill_checklist.py`: Fills a specific checklist using manuscript content and Ollama, generating a PDF.
*   `templates.py`: Contains the structure (item headings) for the supported checklists. 