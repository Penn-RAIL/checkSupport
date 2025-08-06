#python fill_checklist.py --checklist ./files/prismaChecklist.pdf --manuscript ./files/test2.pdf --output filled_report.pdf

import argparse
import os
import sys
import requests
import json
import logging
import re
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.units import inch
from reportlab.lib import colors

# Reuse text extraction and model path from suggest_checklist
from suggest_checklist import extract_manuscript_text, OLLAMA_API_URL

# Define the default model name
DEFAULT_OLLAMA_MODEL = "llama3.1:8b-instruct-q8_0"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def read_checklist_file(checklist_path):
    """Reads and parses a checklist file to extract sections and items."""
    logger.info(f"Reading checklist file: {checklist_path}")
    
    if not os.path.exists(checklist_path):
        logger.error(f"Checklist file not found: {checklist_path}")
        return None
    
    try:
        # Extract text from the checklist file (supporting PDF, DOCX, TXT)
        content = extract_manuscript_text(checklist_path)
        if content is None or not content.strip():
            logger.error(f"Could not extract text from checklist file: {checklist_path}")
            return None
        
        # Process the checklist content
        return process_checklist_content(content)
        
    except Exception as e:
        logger.error(f"Error parsing checklist file: {e}")
        return None

def process_checklist_content(content):
    """Process the extracted checklist content to identify sections and items."""
    logger.info("Processing checklist content")
    
    # Try to detect the type of checklist based on content
    checklist_type = detect_checklist_type(content)
    logger.info(f"Detected checklist type: {checklist_type}")
    
    if checklist_type == "PRISMA":
        sections = process_prisma_checklist(content)
    elif checklist_type == "STARD":
        sections = process_stard_checklist(content)
    elif checklist_type == "CONSORT":
        sections = process_consort_checklist(content)
    elif checklist_type == "custom":
        sections = process_custom_checklist(content)
    else:
        # Default generic processing
        sections = process_generic_checklist(content)
    
    logger.info(f"Extracted {len(sections)} sections from checklist")
    return sections

def detect_checklist_type(content):
    """Detect the type of checklist based on content patterns."""
    content_lower = content.lower()
    
    if "prisma" in content_lower and ("systematic review" in content_lower or "meta-analysis" in content_lower):
        return "PRISMA"
    elif "stard" in content_lower and "diagnostic accuracy" in content_lower:
        return "STARD"
    elif "consort" in content_lower and "randomized" in content_lower:
        return "CONSORT"
    elif "::" in content or (content.count("#") > 5):
        return "custom"
    else:
        return "generic"

def process_prisma_checklist(content):
    """Process a PRISMA checklist format."""
    sections = []
    
    # Match section titles and items
    section_patterns = [
        r"Title\s+and\s+Abstract",
        r"Introduction",
        r"Methods",
        r"Results",
        r"Discussion",
        r"Funding"
    ]
    
    current_section = None
    lines = content.split('\n')
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Check if this is a section header
        is_section_header = any(re.search(pattern, line, re.IGNORECASE) for pattern in section_patterns)
        
        if is_section_header:
            current_section = line
            sections.append({
                "section": current_section,
                "items": [],
                "guidance": "Extract information related to this section from the manuscript."
            })
        elif current_section and "#" in line:
            # This is likely an item number
            item_text = line.split("#", 1)[1].strip() if "#" in line else line
            if sections:
                sections[-1]["items"].append(item_text)
        elif current_section and line:
            # This could be an item or description
            if sections and line:
                sections[-1]["items"].append(line)
    
    return sections

def process_stard_checklist(content):
    """Process a STARD checklist format."""
    # Similar to PRISMA but with STARD-specific patterns
    return process_generic_checklist(content)

def process_consort_checklist(content):
    """Process a CONSORT checklist format."""
    # Similar to PRISMA but with CONSORT-specific patterns
    return process_generic_checklist(content)

def process_custom_checklist(content):
    """Process a custom checklist format with :: separator."""
    sections = []
    current_section = "General"
    items = []
    
    lines = content.split('\n')
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        if '::' in line:
            # This is an instruction line
            item_text, instruction = [part.strip() for part in line.split('::', 1)]
            
            # Check if this is a new section
            if ':' in item_text and len(item_text.split(':', 1)[0]) < 30:
                section_name = item_text.split(':', 1)[0].strip()
                if items and current_section:
                    # Add the previous section
                    sections.append({
                        "section": current_section,
                        "items": items,
                        "guidance": "Extract information related to this section from the manuscript."
                    })
                    items = []
                current_section = section_name
            
            items.append({
                "text": item_text,
                "instruction": instruction
            })
        else:
            # This is just an item
            items.append({
                "text": line,
                "instruction": "Answer based on the manuscript text."
            })
    
    # Add the last section
    if items:
        sections.append({
            "section": current_section,
            "items": items,
            "guidance": "Extract information related to this section from the manuscript."
        })
    
    return sections

def process_generic_checklist(content):
    """Process a generic checklist by trying to identify sections and items."""
    sections = []
    current_section = "General"
    items = []
    
    # Look for potential section headers (capitalized lines, lines ending with ":", etc.)
    lines = content.split('\n')
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Check if this looks like a section header
        is_section_header = (line.isupper() or 
                           line.endswith(':') or 
                           (len(line) < 50 and line.split()[0].istitle()))
        
        if is_section_header:
            # Save previous section if it has items
            if items:
                sections.append({
                    "section": current_section,
                    "items": items,
                    "guidance": "Extract information related to this section from the manuscript."
                })
                items = []
            current_section = line
        else:
            # This is an item
            items.append({
                "text": line,
                "instruction": "Answer based on the manuscript text."
            })
    
    # Add the last section
    if items:
        sections.append({
            "section": current_section,
            "items": items,
            "guidance": "Extract information related to this section from the manuscript."
        })
    
    return sections

def preprocess_checklist(sections, manuscript_text, ollama_model_name):
    """Preprocess the checklist to understand how to fill each section."""
    logger.info("Preprocessing checklist to understand filling instructions")
    
    # Extract section names for guidance
    section_names = [section["section"] for section in sections]
    
    prompt = f"""I need to fill a medical/scientific checklist based on a manuscript. The checklist has the following sections:

{', '.join(section_names)}

The manuscript appears to be a medical/scientific paper. For each section, I need to extract relevant information.

Provide specific guidance on how to approach extracting information for each of these sections from a scientific manuscript.
Be specific about what types of content to look for in each section."""

    payload = {
        "model": ollama_model_name,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.7
        }
    }

    try:
        logger.info(f"Consulting {ollama_model_name} for checklist preprocessing guidance")
        response = requests.post(OLLAMA_API_URL, json=payload)
        response.raise_for_status()
        
        response_data = response.json()
        general_guidance = response_data.get('response', '').strip()
        
        # Now get specific guidance for each section
        for i, section in enumerate(sections):
            section_prompt = f"""For the checklist section "{section['section']}" in a medical/scientific paper checklist:

1. What specific information should I look for in the manuscript?
2. Where in a scientific manuscript would this information typically be found?
3. What are key phrases or concepts that would indicate this information?

Provide specific, concise guidance."""

            payload["prompt"] = section_prompt
            
            try:
                logger.info(f"Getting guidance for section: {section['section']}")
                response = requests.post(OLLAMA_API_URL, json=payload)
                response.raise_for_status()
                
                response_data = response.json()
                section_guidance = response_data.get('response', '').strip()
                
                # Update the section with the specific guidance
                sections[i]["guidance"] = section_guidance
            except Exception as e:
                logger.warning(f"Error getting guidance for section {section['section']}: {e}")
                # Keep the default guidance
        
        logger.info("Successfully obtained preprocessing guidance")
        return sections, general_guidance
        
    except Exception as e:
        logger.error(f"Error during checklist preprocessing: {e}")
        return sections, "Failed to obtain preprocessing guidance. Proceeding with default approach."

def generate_section_answers(section, manuscript_text, ollama_model_name, general_guidance):
    """Generates answers for an entire section of the checklist."""
    logger.info(f"Processing section: {section['section']}")
    
    section_answers = []
    
    # First, get relevant text for this section
    section_text = extract_section_text(section, manuscript_text, ollama_model_name)
    
    # Now process each item in the section
    items = section["items"]
    for item in items:
        if isinstance(item, dict):
            item_text = item["text"]
            instruction = item["instruction"]
        else:
            item_text = item
            instruction = "Answer based on the manuscript text."
            
        answer = generate_item_answer(
            item_text=item_text,
            instruction=instruction,
            section_guidance=section["guidance"],
            general_guidance=general_guidance,
            manuscript_text=manuscript_text,
            section_text=section_text,
            ollama_model_name=ollama_model_name
        )
        
        section_answers.append({
            "item": item_text,
            "answer": answer
        })
    
    return section_answers

def extract_section_text(section, manuscript_text, ollama_model_name):
    """Extract the most relevant text from the manuscript for a specific section."""
    logger.info(f"Extracting relevant text for section: {section['section']}")
    
    prompt = f"""Given the following manuscript text, extract the portions most relevant to the "{section['section']}" section of a scientific checklist.

Section Guidance: {section['guidance']}

Manuscript Text:
---
{manuscript_text[:5000]}  # Limit to first 5000 chars to avoid token limits
---

Extract only the most relevant parts of the text for the "{section['section']}" section."""

    payload = {
        "model": ollama_model_name,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.3
        }
    }

    try:
        response = requests.post(OLLAMA_API_URL, json=payload)
        response.raise_for_status()
        
        response_data = response.json()
        section_text = response_data.get('response', '').strip()
        
        # If we didn't get much text, try with the next part of the manuscript
        if len(section_text) < 100 and len(manuscript_text) > 5000:
            prompt = prompt.replace(manuscript_text[:5000], manuscript_text[5000:10000])
            payload["prompt"] = prompt
            
            response = requests.post(OLLAMA_API_URL, json=payload)
            response.raise_for_status()
            
            response_data = response.json()
            additional_text = response_data.get('response', '').strip()
            section_text += "\n\n" + additional_text
        
        return section_text
        
    except Exception as e:
        logger.warning(f"Error extracting section text for {section['section']}: {e}")
        return manuscript_text[:1500]  # Return a portion of the manuscript as fallback

def generate_item_answer(item_text, instruction, section_guidance, general_guidance, manuscript_text, section_text, ollama_model_name):
    """Generates a short answer for a checklist item using Ollama with specific instructions."""
    logger.info(f"Generating answer for: '{item_text[:50]}...'")
    
    # Combining section-specific text with a smaller portion of the full manuscript
    context_text = f"{section_text}\n\n--- Additional manuscript text ---\n\n{manuscript_text[:1000]}"
    
    prompt = f"""Based on the following manuscript text, provide a concise answer for the checklist item: '{item_text}'

Specific instruction for this item: {instruction}

Section guidance: {section_guidance}

Manuscript Text:
---
{context_text}
---

Checklist Item: {item_text}

Answer concisely based only on the provided text. If the information isn't present, state that.
Answer: """

    payload = {
        "model": ollama_model_name,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.5,
            "stop": ["\\n", "Checklist Item:"]
        }
    }

    try:
        response = requests.post(OLLAMA_API_URL, json=payload)
        response.raise_for_status()

        response_data = response.json()
        answer = response_data.get('response', '').strip()

        # Basic cleanup
        if not answer or answer.lower().startswith("answer:"):
            answer = answer.split(':', 1)[-1].strip()
        if not answer:
            answer = "Information not found in the provided text snippet."
            
        logger.info(f"Successfully generated answer for: '{item_text[:50]}...'")
        return answer

    except requests.exceptions.ConnectionError:
        error_msg = f"Could not connect to Ollama API at {OLLAMA_API_URL}. Is Ollama running?"
        logger.error(error_msg)
        return f"Error: Ollama connection failed for item '{item_text}'"
    except requests.exceptions.RequestException as e:
        error_msg = f"Error during Ollama API request for item '{item_text}': {e}"
        logger.error(error_msg)
        return f"Error: Ollama request failed for item '{item_text}': {e}"
    except json.JSONDecodeError:
        error_msg = f"Could not decode JSON response from Ollama for item '{item_text}'"
        logger.error(error_msg)
        return f"Error: Ollama JSON decode failed for item '{item_text}'"
    except Exception as e:
        error_msg = f"An unexpected error occurred generating answer for item '{item_text}': {e}"
        logger.error(error_msg)
        return f"Error generating answer: {e}"

def create_pdf(output_path, checklist_name, sections, all_answers, general_guidance=None):
    """Creates a PDF document using ReportLab."""
    try:
        logger.info(f"Creating PDF report at {output_path}")
        doc = SimpleDocTemplate(output_path)
        styles = getSampleStyleSheet()
        story = []

        # Create a title style
        title_style = styles['Heading1']
        title_style.alignment = TA_CENTER
        title_style.spaceAfter = 0.3*inch
        
        # Create section style
        section_style = styles['Heading2']
        section_style.spaceAfter = 0.1*inch
        section_style.spaceBefore = 0.2*inch
        
        # Create item style
        item_style = styles['Heading3']
        item_style.spaceBefore = 0.15*inch
        
        # Create guidance style
        guidance_style = ParagraphStyle(
            'Guidance',
            parent=styles['Italic'],
            textColor=colors.darkblue,
            spaceBefore=6,
            spaceAfter=6
        )
        
        # Create answer style
        answer_style = ParagraphStyle(
            'Answer',
            parent=styles['BodyText'],
            leftIndent=20,
            spaceBefore=6,
            spaceAfter=12,
            borderColor=colors.lightgrey,
            borderWidth=1,
            borderPadding=5,
            borderRadius=5
        )

        # Title
        story.append(Paragraph(f"Filled Checklist: {os.path.basename(checklist_name)}", title_style))
        
        # Add general preprocessing guidance if available
        if general_guidance:
            story.append(Paragraph("General Guidance:", section_style))
            story.append(Paragraph(general_guidance, guidance_style))
            story.append(Spacer(1, 0.2*inch))

        # Process each section
        for section_index, section in enumerate(sections):
            section_name = section["section"]
            story.append(Paragraph(f"Section {section_index+1}: {section_name}", section_style))
            
            # Add section guidance
            if "guidance" in section and section["guidance"]:
                story.append(Paragraph("Guidance:", item_style))
                story.append(Paragraph(section["guidance"], guidance_style))
            
            # Add all items and answers for this section
            section_answers = all_answers[section_index]
            for i, answer_data in enumerate(section_answers):
                story.append(Paragraph(f"Item {section_index+1}.{i+1}: {answer_data['item']}", item_style))
                story.append(Paragraph(answer_data['answer'], answer_style))
            
            # Add a spacer after each section
            story.append(Spacer(1, 0.2*inch))

        doc.build(story)
        logger.info(f"PDF report successfully created at {output_path}")
        return True
    except Exception as e:
        logger.error(f"Error creating PDF {output_path}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Fill a custom checklist based on a manuscript using an Ollama model and generate a PDF.")
    parser.add_argument("--checklist", required=True, help="Path to the checklist file (.pdf, .docx, .txt)")
    parser.add_argument("--manuscript", required=True, help="Path to the manuscript file (.pdf, .docx, .txt)")
    parser.add_argument("--output", default="filled_checklist.pdf", help="Path to save the generated PDF checklist (default: filled_checklist.pdf)")
    parser.add_argument("--model", default=DEFAULT_OLLAMA_MODEL, help=f"Name of the Ollama model to use (default: {DEFAULT_OLLAMA_MODEL})")

    args = parser.parse_args()

    # Validate paths
    if not os.path.exists(args.manuscript):
        logger.error(f"Manuscript file not found at {args.manuscript}")
        sys.exit(1)
        
    if not os.path.exists(args.checklist):
        logger.error(f"Checklist file not found at {args.checklist}")
        sys.exit(1)

    logger.info(f"Processing manuscript: {args.manuscript}")
    manuscript_text = extract_manuscript_text(args.manuscript)
    if manuscript_text is None or not manuscript_text.strip():
        logger.error("Could not extract text from the manuscript or it is empty.")
        sys.exit(1)

    # Read and parse the checklist file
    sections = read_checklist_file(args.checklist)
    if sections is None:
        logger.error(f"Failed to parse checklist file: {args.checklist}")
        sys.exit(1)
    
    # Preprocess the checklist to get guidance for each section
    processed_sections, general_guidance = preprocess_checklist(sections, manuscript_text, args.model)
    
    logger.info(f"Filling checklist with {len(processed_sections)} sections using Ollama model '{args.model}'...")
    
    # Process each section to get answers
    all_section_answers = []
    for section in processed_sections:
        section_answers = generate_section_answers(
            section=section,
            manuscript_text=manuscript_text,
            ollama_model_name=args.model,
            general_guidance=general_guidance
        )
        all_section_answers.append(section_answers)
    
    logger.info(f"Generating PDF report at {args.output}...")
    success = create_pdf(args.output, args.checklist, processed_sections, all_section_answers, general_guidance)

    if success:
        logger.info(f"Checklist successfully generated: {args.output}")
    else:
        logger.error("Failed to generate PDF report.")
        sys.exit(1)

if __name__ == "__main__":
    main() 