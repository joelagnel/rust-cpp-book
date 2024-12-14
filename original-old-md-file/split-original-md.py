import os
import re
import shutil

def create_directory_structure():
    # Create base directory
    base_dir = "rust-book"
    chapters_dir = os.path.join(base_dir, "chapters")
    
    # Remove if exists and recreate
    if os.path.exists(base_dir):
        shutil.rmtree(base_dir)
    
    os.makedirs(chapters_dir)
    
    return base_dir, chapters_dir

def create_metadata_yaml(base_dir):
    metadata = """---
title: Rust for C and C++ programmers
author: Your Name
date: 2024
toc: true
toc-depth: 2
numbersections: true
geometry: margin=1in
linkcolor: blue
header-includes: |
    \\usepackage{fancyhdr}
    \\pagestyle{fancy}
    \\fancyhead[CO,CE]{Rust for C and C++ programmers}
---
"""
    with open(os.path.join(base_dir, "metadata.yaml"), 'w') as f:
        f.write(metadata)

def create_build_script(base_dir):
    build_script = """#!/bin/bash
pandoc metadata.yaml \
    chapters/*.md \
    --from markdown+smart \
    --pdf-engine=xelatex \
    --toc \
    --number-sections \
    -o rust-book.pdf
"""
    with open(os.path.join(base_dir, "build.sh"), 'w') as f:
        f.write(build_script)
    # Make the build script executable
    os.chmod(os.path.join(base_dir, "build.sh"), 0o755)

def split_content(content, chapters_dir):
    # Regular expression to match section headers
    sections = re.split(r'^## ', content, flags=re.MULTILINE)
    
    # Write introduction
    intro = sections[0]
    with open(os.path.join(chapters_dir, "01-introduction.md"), 'w') as f:
        f.write(intro.strip() + "\n\n\\pagebreak\n")
    
    # Process other sections
    for i, section in enumerate(sections[1:], start=2):
        # Get the section title from the first line
        title = section.split('\n')[0].strip()
        # Convert title to filename-friendly format
        filename = f"{i:02d}-{title.lower().replace(' ', '-')}.md"
        filename = re.sub(r'[^a-z0-9\-]', '', filename)
        
        # Write content with section header restored
        with open(os.path.join(chapters_dir, filename), 'w') as f:
            f.write(f"## {section.strip()}\n\n\\pagebreak\n")

def main():
    # Read the original markdown file
    with open('rust.md', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Create directory structure
    base_dir, chapters_dir = create_directory_structure()
    
    # Create metadata.yaml
    create_metadata_yaml(base_dir)
    
    # Create build script
    create_build_script(base_dir)
    
    # Split content into chapters
    split_content(content, chapters_dir)
    
    print(f"Book structure created in {base_dir}/")
    print("To build the PDF:")
    print(f"cd {base_dir} && ./build.sh")

if __name__ == "__main__":
    main()