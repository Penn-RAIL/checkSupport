import sys
import os
from suggest_checklist import extract_manuscript_text

# Add the checklist_cli directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def view_file_content(filepath):
    print(f"\n--- Viewing content of {filepath} ---")
    content = extract_manuscript_text(filepath)
    if content:
        print(f"Content length: {len(content)} characters")
        print("First 500 characters:")
        print(content[:500])
        print("...")
    else:
        print(f"Failed to extract content from {filepath}")

# View the checklist file
view_file_content("files/prismaChecklist.pdf")

# View the manuscript file
view_file_content("files/test2.pdf") 