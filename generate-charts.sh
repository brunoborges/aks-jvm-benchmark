#!/bin/bash

# HdrHistogram Chart Generator Wrapper
# Generates visualization charts from benchmark results using Python

set -e

RESULTS_DIR=${1:-""}

if [ -z "$RESULTS_DIR" ]; then
    echo "❌ Error: Results directory not specified"
    echo ""
    echo "Usage: ./generate-charts.sh <results-directory>"
    echo ""
    echo "Example:"
    echo "  ./generate-charts.sh benchmark-results/20251007-021703"
    echo ""
    exit 1
fi

if [ ! -d "$RESULTS_DIR" ]; then
    echo "❌ Error: Directory not found: $RESULTS_DIR"
    exit 1
fi

# Use the virtual environment Python if it exists, otherwise use python3
if [ -f ".venv/bin/python" ]; then
    PYTHON_CMD=".venv/bin/python"
    echo "✓ Using virtual environment Python"
else
    PYTHON_CMD="python3"
    echo "⚠️  Using system Python 3"
    
    # Check if Python 3 is installed
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python 3 is not installed"
        echo "   Install from: https://www.python.org/"
        exit 1
    fi
    
    # Check if matplotlib is installed
    if ! python3 -c "import matplotlib" 2>/dev/null; then
        echo "❌ matplotlib is not installed"
        echo ""
        echo "Installing matplotlib..."
        pip3 install matplotlib
        echo ""
    fi
fi

# Run the Python chart generator
$PYTHON_CMD chart-generator/generate_charts.py "$RESULTS_DIR"
