#!/bin/bash

# setup.sh - Creates the Rust book project structure and files

# Create main project directories
mkdir -p rust-book/{chapters,templates,styles,images}

# Create build script
cat > rust-book/build.sh << 'EOF'
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
common_opts="--from markdown+smart --toc --number-sections"

if [ "$format" = "html" ]; then
    echo "Generating HTML..."
    
    # Create output directory
    mkdir -p html_book
    
    # Generate HTML with modern styling and navigation
    pandoc metadata.yaml \
        chapters/*.md \
        $common_opts \
        --standalone \
        --template=templates/html.template \
        --css=styles/book.css \
        --section-divs \
        --split-level=1 \
        --mathjax \
        --toc-depth=3 \
        --file-scope \
        --resource-path=.:images \
        --output-dir=html_book \
        --self-contained=false \
        -o html_book/index.html

    # Copy CSS and assets
    mkdir -p html_book/styles
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
EOF

# Create HTML template
cat > rust-book/templates/html.template << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$pagetitle$</title>
    <link rel="stylesheet" href="styles/book.css">
</head>
<body>
    <div class="container">
        <nav class="sidebar">
            <div class="sidebar-header">
                <h1>$title$</h1>
            </div>
            $if(toc)$
            <div class="toc">
                $toc$
            </div>
            $endif$
        </nav>
        <main class="content">
            $body$
        </main>
    </div>
</body>
</html>
EOF

# Create CSS file
cat > rust-book/styles/book.css << 'EOF'
:root {
    --sidebar-width: 300px;
    --primary-color: #2b6cb0;
    --background-color: #f7fafc;
}

body {
    margin: 0;
    padding: 0;
    font-family: system-ui, -apple-system, sans-serif;
    line-height: 1.6;
    color: #2d3748;
    background: var(--background-color);
}

.container {
    display: flex;
    min-height: 100vh;
}

.sidebar {
    width: var(--sidebar-width);
    background: white;
    border-right: 1px solid #e2e8f0;
    position: fixed;
    height: 100vh;
    overflow-y: auto;
    padding: 2rem;
    box-sizing: border-box;
}

.sidebar-header {
    margin-bottom: 2rem;
}

.content {
    margin-left: var(--sidebar-width);
    padding: 2rem 4rem;
    max-width: 800px;
    width: 100%;
}

.toc {
    font-size: 0.95rem;
}

.toc ul {
    list-style: none;
    padding-left: 1.5rem;
}

.toc a {
    color: #4a5568;
    text-decoration: none;
    display: block;
    padding: 0.3rem 0;
}

.toc a:hover {
    color: var(--primary-color);
}

h1, h2, h3, h4, h5, h6 {
    color: #1a202c;
    margin-top: 2rem;
    margin-bottom: 1rem;
}

code {
    background: #edf2f7;
    padding: 0.2em 0.4em;
    border-radius: 3px;
    font-size: 0.9em;
}

pre {
    background: #2d3748;
    color: #e2e8f0;
    padding: 1rem;
    border-radius: 5px;
    overflow-x: auto;
}

pre code {
    background: none;
    color: inherit;
    padding: 0;
}

a {
    color: var(--primary-color);
}

@media (max-width: 768px) {
    .sidebar {
        display: none;
    }
    
    .content {
        margin-left: 0;
        padding: 1rem;
    }
}
EOF

# Make build script executable
chmod +x rust-book/build.sh

echo "Project structure created successfully!"