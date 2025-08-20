"""
CheckSupport Utilities - Common functions and prompts
"""

import os
import sys
import requests
import json
from PyPDF2 import PdfReader
import docx
from pathlib import Path

# Constants
DEFAULT_OLLAMA_MODEL = "mistral:instruct"
OLLAMA_API_URL = "http://localhost:11434/api/generate"

def extract_text_from_pdf(filepath):
    """Extracts text from a PDF file."""
    try:
        reader = PdfReader(filepath)
        text = ""
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"
        return text
    except Exception as e:
        print(f"Error reading PDF file {filepath}: {e}", file=sys.stderr)
        return None

def extract_text_from_docx(filepath):
    """Extracts text from a DOCX file."""
    try:
        doc = docx.Document(filepath)
        text = "\n".join([para.text for para in doc.paragraphs])
        return text
    except Exception as e:
        print(f"Error reading DOCX file {filepath}: {e}", file=sys.stderr)
        return None

def extract_text_from_txt(filepath):
    """Extracts text from a TXT file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading TXT file {filepath}: {e}", file=sys.stderr)
        return None

def extract_manuscript_text(filepath):
    """Extracts text from manuscript based on file extension."""
    _, ext = os.path.splitext(filepath)
    ext = ext.lower()

    if not os.path.exists(filepath):
         print(f"Error: Manuscript file not found at {filepath}", file=sys.stderr)
         return None

    if ext == '.pdf':
        return extract_text_from_pdf(filepath)
    elif ext == '.docx':
        return extract_text_from_docx(filepath)
    elif ext == '.txt':
        return extract_text_from_txt(filepath)
    else:
        print(f"Error: Unsupported file type '{ext}'. Please provide a .pdf, .docx, or .txt file.", file=sys.stderr)
        return None

def check_model_exists(model_name):
    """Check if the specified Ollama model exists."""
    try:
        # First check if Ollama is running
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        response.raise_for_status()
        
        models_data = response.json()
        available_models = [model['name'] for model in models_data.get('models', [])]
        
        if model_name in available_models:
            return True
        else:
            print(f"Error: Model '{model_name}' not found.")
            print(f"Available models: {', '.join(available_models)}")
            print(f"To install the model: ollama pull {model_name}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"Error: Could not connect to Ollama API. Is Ollama running?")
        print("Start Ollama with: ./checksupport.sh start")
        return False
    except Exception as e:
        print(f"Error checking model availability: {e}")
        return False

def get_suggest_prompt(manuscript_text, available_checklists):
    """Get the prompt for checklist suggestion."""
    available_checklists_str = ", ".join(available_checklists)
    
    prompt = f"""Analyze the following research manuscript abstract or introduction text and determine the most appropriate reporting checklist based on the Enhancing the QUAlity and Transparency Of health Research (EQUATOR) Network.

Manuscript Text:
---
{manuscript_text[:2000]}  # Limit prompt length
---

Available checklists: {available_checklists_str}

Based on the text, which of the following reporting checklists is most suitable?
Choose exactly ONE checklist name from the list above. Your answer should be only the name of the checklist (e.g., PRISMA)."""

    return prompt

def call_ollama_api(prompt, model_name, temperature=0.2):
    """Make a call to the Ollama API."""
    payload = {
        "model": model_name,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": temperature,
        }
    }

    try:
        response = requests.post(OLLAMA_API_URL, json=payload, timeout=30)
        response.raise_for_status()

        response_data = response.json()
        response_text = response_data.get('response', '').strip()

        return response_text

    except requests.exceptions.ConnectionError:
        print(f"Error: Could not connect to Ollama API at {OLLAMA_API_URL}. Is Ollama running?", file=sys.stderr)
        return None
    except requests.exceptions.RequestException as e:
        print(f"Error during Ollama API request: {e}", file=sys.stderr)
        try:
            print(f"Response body: {response.text}", file=sys.stderr)
        except:
            pass
        return None
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON response from Ollama: {response.text}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        return None 