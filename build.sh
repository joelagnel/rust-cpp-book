#!/bin/bash

# Default output format is PDF
format="pdf"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --html) format="html" ;;
        --pdf)  format="pdf" ;;
        *)      echo "Unknown parameter: $1"
                echo "Usage: $0 [--html|--pdf]"
                exit 1 ;;
    esac
    shift
done

# Common pandoc options
common_opts="--from markdown+smart --toc --toc-depth=1 \
    --number-sections \
    --top-level-division=chapter \
    --shift-heading-level-by=-1"

if [ "$format" = "html" ]; then
    echo "Generating HTML..."
    
    # Create output directory
    mkdir -p html_book/styles
    # Generate HTML with modern styling and navigation
    # BROKEN
    pandoc metadata.yaml \
        chapters/*.md \
        $common_opts \
        --standalone \
        --template=templates/html.template \
        --css=styles/book.css \
        --mathjax \
        --toc-depth=2 \
        --section-divs \
        --file-scope \
        --split-level=2 \
        -o html_book/

    # Copy CSS and assets
    cp styles/book.css html_book/styles/
    
    # If you have images, copy them too
    if [ -d "images" ]; then
        cp -r images html_book/
    fi

else
    echo "Generating PDF..."
    pandoc metadata.yaml \
        chapters/*.md \
        $common_opts \
        --pdf-engine=xelatex \
        -o rust-book.pdf
fi