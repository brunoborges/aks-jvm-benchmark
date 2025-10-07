# HdrHistogram Chart Generator

This tool automatically generates latency comparison charts from benchmark results using the HdrHistogram online plotter.

## Setup

Install dependencies:

```bash
npm install
```

Install Playwright browsers:

```bash
npx playwright install chromium
```

## Usage

### Via Wrapper Script (Recommended)

From the project root:

```bash
./generate-charts.sh benchmark-results/20250107-143022
```

### Direct Execution

From this directory:

```bash
node generate-charts.js ../benchmark-results/20250107-143022
```

## How It Works

1. Launches a headless Chrome browser using Playwright
2. Navigates to http://hdrhistogram.github.io/HdrHistogram/plotFiles.html
3. Converts wrk benchmark output to HdrHistogram format
4. Uploads data files for each configuration
5. Takes screenshots of the generated charts
6. Saves comparison charts as PNG images

## Output

Charts are saved in the results directory:

```
benchmark-results/20250107-143022/charts/
├── comparison_simple.png    # Simple JSON endpoint comparison
└── comparison_cpu.png       # CPU-intensive endpoint comparison
```

## Configuration Colors

Each configuration is assigned a distinct color:

- **6x1**: Red (#FF6B6B)
- **3x2**: Teal (#4ECDC4)
- **2x3**: Blue (#45B7D1)
- **2x2**: Orange (#FFA07A)

## Troubleshooting

### Playwright Installation

If browser installation fails:

```bash
# macOS
export PLAYWRIGHT_BROWSERS_PATH=$HOME/Library/Caches/ms-playwright

# Linux
export PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright

npx playwright install chromium
```

### Missing Data

If charts are empty or missing:
- Verify benchmark files contain latency data
- Check file paths are correct
- Ensure wrk was run with `-L` flag for latency output

### Screenshot Issues

If screenshots are blank:
- Increase `waitForTimeout` values in generate-charts.js
- Check browser console for errors
- Try running in non-headless mode for debugging:
  ```javascript
  const browser = await chromium.launch({ headless: false });
  ```

## Development

### Testing Locally

```bash
# Run with a sample results directory
node generate-charts.js ../benchmark-results/sample

# Watch for changes
npm run test
```

### Modifying Chart Appearance

Edit the `CONFIG_COLORS` object in `generate-charts.js` to change colors.

For more control over the chart appearance, you can:
1. Modify the HdrHistogram plotter settings programmatically
2. Take multiple screenshots at different zoom levels
3. Add annotations or labels using Playwright's page manipulation features

## Dependencies

- **playwright**: Web automation for chart generation
- **fs**: File system operations
- **path**: Path utilities

No external libraries required for image processing - uses native Playwright screenshot capabilities.

## License

Same as parent project
