#!/bin/bash

# HdrHistogram Chart Generator Wrapper
# Generates visualization charts from benchmark results

set -e

RESULTS_DIR=${1:-""}

if [ -z "$RESULTS_DIR" ]; then
    echo "❌ Error: Results directory not specified"
    echo ""
    echo "Usage: ./generate-charts.sh <results-directory>"
    echo ""
    echo "Example:"
    echo "  ./generate-charts.sh benchmark-results/20250107-143022"
    echo ""
    exit 1
fi

if [ ! -d "$RESULTS_DIR" ]; then
    echo "❌ Error: Directory not found: $RESULTS_DIR"
    exit 1
fi

echo "======================================"
echo "HdrHistogram Chart Generator"
echo "======================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "   Install from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo ""

# Navigate to chart generator directory
cd chart-generator

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Install Playwright browsers if needed
if [ ! -d "$HOME/.cache/ms-playwright" ] && [ ! -d "$HOME/Library/Caches/ms-playwright" ]; then
    echo "🌐 Installing Playwright browsers..."
    npx playwright install chromium
    echo ""
fi

# Run the chart generator
echo "🎨 Generating charts..."
echo ""

node generate-charts.js "../$RESULTS_DIR"

cd ..

echo ""
echo "✅ Done! Open the charts directory to view results:"
echo "   open $RESULTS_DIR/charts/"
echo ""
