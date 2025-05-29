#Test python suggest_checklist.py ./files/test1.pdf   

import argparse
import os
import sys
import requests
import json
from PyPDF2 import PdfReader
import docx # python-docx
from templates import get_template_names

DEFAULT_OLLAMA_MODEL = "llama3.1:8b-instruct-q8_0" # Updated default model
OLLAMA_API_URL = "http://localhost:11434/api/generate" # Default Ollama API endpoint

def extract_text_from_pdf(filepath):
    """Extracts text from a PDF file."""
    try:
        reader = PdfReader(filepath)
        text = ""
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\\n"
        print(f"Extracted text: {text}")
        return text
    except Exception as e:
        print(f"Error reading PDF file {filepath}: {e}", file=sys.stderr)
        return None

def extract_text_from_docx(filepath):
    """Extracts text from a DOCX file."""
    try:
        doc = docx.Document(filepath)
        text = "\\n".join([para.text for para in doc.paragraphs])
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

def suggest_checklist_with_ollama(manuscript_text, ollama_model_name):
    """Uses Ollama to suggest a checklist based on manuscript text."""
    checklist_names = get_template_names()
    available_checklists_str = ", ".join(checklist_names)

    prompt = f"""Analyze the following research manuscript abstract or introduction text and determine the most appropriate reporting checklist based on the Enhancing the QUAlity and Transparency Of health Research (EQUATOR) Network.
Manuscript Text:
---
{manuscript_text} # Limit prompt length
---
Based on the text, which of the following reporting checklists is most suitable?
"""

# Available checklists: {available_checklists_str}
# Choose exactly ONE checklist name from the list above. Your answer should be only the name of the checklist (e.g., PRISMA).
    # DEBUG: Print the exact prompt being sent
    print("--- Sending Prompt to Ollama ---")
    print(prompt)
    print("-------------------------------")

    payload = {
        "model": ollama_model_name,
        "prompt": prompt,
        "stream": False, # Get the full response at once
        "options": {
            "temperature": 0.2,
            # "stop": checklist_names # <-- Temporarily comment out stop tokens for debugging
        }
    }

    # DEBUG: Print the payload
    print(f"--- Sending Payload to Ollama ---")
    print(json.dumps(payload, indent=2)) # Use json.dumps for pretty printing
    print("-------------------------------")

    try:
        print(f"Sending request to Ollama model '{ollama_model_name}'...")
        response = requests.post(OLLAMA_API_URL, json=payload)
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)

        response_data = response.json()
        response_text = response_data.get('response', '').strip()

        print(f"Ollama raw response: '{response_text}'") # Debugging output

        # Find the checklist name in the response (existing logic)
        suggested_checklist = None
        for name in checklist_names:
            # Be a bit more robust in checking containment
            if name.lower() in response_text.lower():
                 # Check if it's the only checklist name mentioned or the most prominent one if needed
                 # For simplicity, take the first match for now.
                 suggested_checklist = name
                 break

        return suggested_checklist

    except requests.exceptions.ConnectionError:
        print(f"Error: Could not connect to Ollama API at {OLLAMA_API_URL}. Is Ollama running?", file=sys.stderr)
        return None
    except requests.exceptions.RequestException as e:
        print(f"Error during Ollama API request: {e}", file=sys.stderr)
        # Print response body if available and helpful
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

def main():
    parser = argparse.ArgumentParser(description="Suggest a reporting checklist for a research manuscript using an Ollama model.")
    parser.add_argument("manuscript", help="Path to the manuscript file (.pdf, .docx, .txt)")
    parser.add_argument("--model", default=DEFAULT_OLLAMA_MODEL, help=f"Name of the Ollama model to use (e.g., mistral:instruct, llama3.1:8b-instruct) (default: {DEFAULT_OLLAMA_MODEL})")

    args = parser.parse_args()

    print(f"Processing manuscript: {args.manuscript}")
    manuscript_text = extract_manuscript_text(args.manuscript)

    if manuscript_text is None:
        sys.exit(1)

    if not manuscript_text.strip():
        print("Error: Could not extract text from the manuscript or the manuscript is empty.", file=sys.stderr)
        sys.exit(1)

    suggested_checklist = suggest_checklist_with_ollama(manuscript_text, args.model)

    if suggested_checklist:
        print(f"Suggested checklist: {suggested_checklist}")
    else:
        print("Could not determine an appropriate checklist.")
        # Add check for connection error vs model failure?


if __name__ == "__main__":
    main() 