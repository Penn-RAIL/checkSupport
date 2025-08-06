#!/usr/bin/env python3
"""
CheckSupport CLI - Main entry point for all CheckSupport commands
"""

import argparse
import sys
import os
from pathlib import Path

# Add the parent directory to the path so we can import our modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from checksupport import __version__, __author__, __description__


def create_parser():
    """Create the main argument parser for CheckSupport CLI."""
    parser = argparse.ArgumentParser(
        prog="checksupport",
        description=__description__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  checksupport suggest manuscript.pdf
  checksupport fill --checklist checklist.pdf --manuscript paper.pdf --output report.pdf
  checksupport suggest --model mistral:instruct paper.docx
  checksupport fill --checklist custom.txt --manuscript study.pdf --output filled_report.pdf
        """
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version=f"CheckSupport {__version__} by {__author__}"
    )
    
    subparsers = parser.add_subparsers(
        dest="command",
        help="Available commands",
        metavar="COMMAND"
    )
    
    # Suggest command
    suggest_parser = subparsers.add_parser(
        "suggest",
        help="Suggest appropriate checklist for a manuscript",
        description="Analyze a manuscript and suggest the most appropriate reporting checklist"
    )
    suggest_parser.add_argument(
        "manuscript",
        help="Path to the manuscript file (.pdf, .docx, .txt)"
    )
    suggest_parser.add_argument(
        "--model",
        default="llama3.1:8b-instruct-q8_0",
        help="Ollama model to use (default: llama3.1:8b-instruct-q8_0)"
    )
    suggest_parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose output"
    )
    
    # Fill command
    fill_parser = subparsers.add_parser(
        "fill",
        help="Fill a checklist based on manuscript content",
        description="Fill a custom checklist based on the content of a manuscript and generate a PDF report"
    )
    fill_parser.add_argument(
        "--checklist",
        required=True,
        help="Path to the checklist file (.pdf, .docx, .txt)"
    )
    fill_parser.add_argument(
        "--manuscript",
        required=True,
        help="Path to the manuscript file (.pdf, .docx, .txt)"
    )
    fill_parser.add_argument(
        "--output",
        default="filled_checklist.pdf",
        help="Path for the generated PDF report (default: filled_checklist.pdf)"
    )
    fill_parser.add_argument(
        "--model",
        default="llama3.1:8b-instruct-q8_0",
        help="Ollama model to use (default: llama3.1:8b-instruct-q8_0)"
    )
    fill_parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose output"
    )
    
    return parser


def main():
    """Main entry point for CheckSupport CLI."""
    parser = create_parser()
    args = parser.parse_args()
    
    # If no command is provided, show help
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        if args.command == "suggest":
            from checksupport.suggest_checklist import suggest_checklist_with_ollama, extract_manuscript_text
            
            # Extract text from manuscript
            manuscript_text = extract_manuscript_text(args.manuscript)
            if manuscript_text is None:
                print(f"Error: Could not extract text from manuscript file: {args.manuscript}")
                sys.exit(1)
            
            # Get suggestion
            suggestion = suggest_checklist_with_ollama(manuscript_text, args.model)
            if suggestion:
                print(f"Suggested checklist: {suggestion}")
            else:
                print("Error: Could not get checklist suggestion")
                sys.exit(1)
                
        elif args.command == "fill":
            from checksupport.fill_checklist import main as fill_main
            
            # Set up arguments for fill_checklist
            sys.argv = [
                "fill-checklist",
                "--checklist", args.checklist,
                "--manuscript", args.manuscript,
                "--output", args.output,
                "--model", args.model
            ]
            if args.verbose:
                sys.argv.append("--verbose")
            
            # Run fill_checklist
            fill_main()
            
        else:
            print(f"Unknown command: {args.command}")
            parser.print_help()
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main() 