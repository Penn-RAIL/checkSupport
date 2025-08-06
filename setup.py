#!/usr/bin/env python3
"""
Setup script for CheckSupport CLI tools
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

with open("requirements.txt", "r", encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

setup(
    name="checksupport",
    version="1.0.0",
    author="CheckSupport Team",
    author_email="support@checksupport.com",
    description="A CLI tool to suggest and fill reporting checklists for research manuscripts using local LLMs via Ollama",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/checksupport/checksupport",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Scientific/Engineering :: Information Analysis",
        "Topic :: Text Processing :: Linguistic",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "fill-checklist=checksupport.fill_checklist:main",
            "suggest-checklist=checksupport.suggest_checklist:main",
            "checksupport=checksupport.cli:main",
        ],
    },
    include_package_data=True,
    zip_safe=False,
) 