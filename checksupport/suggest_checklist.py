import argparse
import sys
from templates import get_template_names
from utils import (
    extract_manuscript_text, 
    check_model_exists, 
    get_suggest_prompt, 
    call_ollama_api,
    DEFAULT_OLLAMA_MODEL
)

def suggest_checklist_with_ollama(manuscript_text, ollama_model_name):
    """Uses Ollama to suggest a checklist based on manuscript text."""
    # Check if model exists
    if not check_model_exists(ollama_model_name):
        return None
    
    checklist_names = get_template_names()
    prompt = get_suggest_prompt(manuscript_text, checklist_names)
    
    response_text = call_ollama_api(prompt, ollama_model_name)
    if response_text is None:
        return None

    # Find the checklist name in the response
    suggested_checklist = None
    for name in checklist_names:
        if name.lower() in response_text.lower():
            suggested_checklist = name
            break

    return suggested_checklist

def main():
    parser = argparse.ArgumentParser(description="Suggest a reporting checklist for a research manuscript using an Ollama model.")
    parser.add_argument("manuscript", help="Path to the manuscript file (.pdf, .docx, .txt)")
    parser.add_argument("--model", default=DEFAULT_OLLAMA_MODEL, help=f"Name of the Ollama model to use (default: {DEFAULT_OLLAMA_MODEL})")

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


if __name__ == "__main__":
    main() 