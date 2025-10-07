#!/usr/bin/env node

import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const HDR_HISTOGRAM_URL = 'http://hdrhistogram.github.io/HdrHistogram/plotFiles.html';
const RESULTS_DIR = process.argv[2] || 'benchmark-results';
const OUTPUT_DIR = path.join(RESULTS_DIR, 'charts');

// Colors for different configurations
const CONFIG_COLORS = {
  '6by1': '#FF6B6B',  // Red
  '3by2': '#4ECDC4',  // Teal
  '2by3': '#45B7D1',  // Blue
  '2by2': '#FFA07A'   // Orange
};

console.log('====================================');
console.log('HdrHistogram Chart Generator');
console.log('====================================\n');

if (!fs.existsSync(RESULTS_DIR)) {
  console.error(`❌ Error: Results directory not found: ${RESULTS_DIR}`);
  console.error('Usage: node generate-charts.js <results-directory>');
  process.exit(1);
}

// Create output directory
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

console.log(`📁 Results directory: ${RESULTS_DIR}`);
console.log(`📁 Output directory: ${OUTPUT_DIR}\n`);

// Convert wrk output to HdrHistogram format
function parseWrkOutput(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  const histogramData = [];
  let inDetailedSection = false;
  
  for (const line of lines) {
    if (line.includes('Detailed Percentile spectrum:')) {
      inDetailedSection = true;
      continue;
    }
    
    if (inDetailedSection) {
      // Parse lines like: "  0.500    0.125  50.00%"
      const match = line.trim().match(/^([\d.]+)\s+([\d.]+)\s+([\d.]+)%/);
      if (match) {
        const percentile = parseFloat(match[1]);
        const latencyMs = parseFloat(match[2]) * 1000; // Convert to microseconds
        histogramData.push({ percentile, latency: latencyMs });
      }
      
      if (line.includes('Mean')) {
        break;
      }
    }
  }
  
  // If no detailed data, extract from summary
  if (histogramData.length === 0) {
    const latencyLine = lines.find(l => l.includes('Latency') && l.includes('avg'));
    if (latencyLine) {
      // Simple extraction for basic visualization
      console.log(`  ⚠️  Using summary data for ${path.basename(filePath)}`);
    }
  }
  
  return histogramData;
}

// Generate comparison chart data
function generateComparisonData(configs, testType) {
  const comparisonData = {};
  
  for (const config of configs) {
    const filePath = path.join(RESULTS_DIR, `${config}_${testType}.txt`);
    if (fs.existsSync(filePath)) {
      const data = parseWrkOutput(filePath);
      if (data.length > 0) {
        comparisonData[config] = data;
      }
    }
  }
  
  return comparisonData;
}

// Main function to generate charts
async function generateCharts() {
  console.log('🌐 Launching browser...\n');
  
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });
  
  const page = await context.newPage();
  
  // Navigate to HdrHistogram plotter
  console.log('📊 Loading HdrHistogram plotter...\n');
  await page.goto(HDR_HISTOGRAM_URL, { waitUntil: 'networkidle' });
  
  const configs = ['6by1', '3by2', '2by3', '2by2'];
  const testTypes = ['simple', 'cpu'];
  
  for (const testType of testTypes) {
    console.log(`\n📈 Generating chart for: ${testType === 'simple' ? 'Simple JSON' : 'CPU-Intensive'} endpoint\n`);
    
    // Reload page for fresh chart
    await page.goto(HDR_HISTOGRAM_URL, { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);
    
    let fileIndex = 0;
    
    for (const config of configs) {
      const filePath = path.join(RESULTS_DIR, `${config}_${testType}.txt`);
      
      if (!fs.existsSync(filePath)) {
        console.log(`  ⚠️  Skipping ${config}: file not found`);
        continue;
      }
      
      console.log(`  📂 Processing ${config}...`);
      
      try {
        // Read the benchmark file
        const fileContent = fs.readFileSync(filePath, 'utf-8');
        
        // Find the file input element
        const fileInput = await page.locator('input[type="file"]').first();
        
        // Create a temporary file with proper histogram format
        const tempFile = path.join(OUTPUT_DIR, `temp_${config}_${testType}.hgrm`);
        
        // Convert wrk output to HdrHistogram format
        // For simplicity, we'll upload the raw file and let the tool parse it
        // Or we can create a proper .hgrm file
        const hgrm = convertToHgrm(fileContent, config);
        fs.writeFileSync(tempFile, hgrm);
        
        // Upload file
        await fileInput.setInputFiles(tempFile);
        await page.waitForTimeout(1500);
        
        // Clean up temp file
        fs.unlinkSync(tempFile);
        
        console.log(`  ✅ Uploaded ${config}`);
        fileIndex++;
        
      } catch (error) {
        console.log(`  ❌ Error processing ${config}: ${error.message}`);
      }
    }
    
    // Wait for chart to render
    await page.waitForTimeout(3000);
    
    // Take screenshot
    const screenshotPath = path.join(OUTPUT_DIR, `comparison_${testType}.png`);
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    
    console.log(`\n  📸 Chart saved: ${screenshotPath}\n`);
  }
  
  await browser.close();
  
  console.log('\n====================================');
  console.log('✅ Chart generation complete!');
  console.log('====================================\n');
  console.log(`📁 Charts saved in: ${OUTPUT_DIR}\n`);
  console.log('Generated charts:');
  console.log('  - comparison_simple.png (Simple JSON endpoint)');
  console.log('  - comparison_cpu.png (CPU-intensive endpoint)\n');
}

// Convert wrk output to HdrHistogram format
function convertToHgrm(wrkOutput, configName) {
  const lines = wrkOutput.split('\n');
  let hgrm = `#[Histogram for ${configName}]\n`;
  hgrm += `#[StartTime: ${Date.now()} (seconds since epoch)]\n`;
  
  // Find latency distribution
  let inDistribution = false;
  
  for (const line of lines) {
    if (line.includes('Latency Distribution')) {
      inDistribution = true;
      continue;
    }
    
    if (inDistribution && line.trim()) {
      // Parse lines like: "50%    1.23ms"
      const match = line.trim().match(/([\d.]+)%\s+([\d.]+)(ms|us|s)/);
      if (match) {
        const percentile = parseFloat(match[1]);
        let latency = parseFloat(match[2]);
        const unit = match[3];
        
        // Convert to microseconds
        if (unit === 'ms') latency *= 1000;
        else if (unit === 's') latency *= 1000000;
        
        // HdrHistogram format: Value, Percentile, TotalCount, 1/(1-Percentile)
        const totalCount = Math.floor(percentile * 100);
        hgrm += `${latency.toFixed(3)} ${(percentile/100).toFixed(6)} ${totalCount} ${(1/(1-percentile/100)).toFixed(2)}\n`;
      }
    }
    
    // Also capture detailed percentile spectrum if available
    if (line.includes('Detailed Percentile spectrum:')) {
      break;
    }
  }
  
  return hgrm;
}

// Run the generator
generateCharts().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
