#!/usr/bin/env python3
"""
HdrHistogram Chart Generator for Benchmark Results
Generates latency percentile comparison charts from wrk benchmark data
"""

import sys
import os
import re
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend

# Configuration
CONFIGS = ['6by1', '3by2', '2by3', '2by2']
CONFIG_COLORS = {
    '6by1': '#FF6B6B',  # Red
    '3by2': '#4ECDC4',  # Teal
    '2by3': '#45B7D1',  # Blue
    '2by2': '#FFA07A'   # Orange
}
CONFIG_LABELS = {
    '6by1': '6 pods × 1 CPU',
    '3by2': '3 pods × 2 CPU',
    '2by3': '2 pods × 3 CPU',
    '2by2': '2 pods × 2 CPU'
}


def parse_wrk_output(file_path, min_percentile=95.0):
    """Parse wrk output file and extract latency percentile data
    
    Args:
        file_path: Path to the wrk output file
        min_percentile: Minimum percentile to include (default: 95.0 for P95+)
    """
    percentiles = []
    latencies = []
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Find the detailed percentile section
    in_section = False
    for line in content.split('\n'):
        if 'Detailed Percentile spectrum:' in line:
            in_section = True
            continue
        
        if in_section:
            # Stop at the summary section
            if line.strip().startswith('#[Mean'):
                break
            
            # Parse data lines: "     0.144     0.000000            1         1.00"
            parts = line.strip().split()
            if len(parts) == 4:
                try:
                    latency = float(parts[0])  # milliseconds
                    percentile = float(parts[1]) * 100  # convert to percentage
                    
                    # Only include data at or above the minimum percentile
                    if percentile >= min_percentile:
                        latencies.append(latency)
                        percentiles.append(percentile)
                except ValueError:
                    continue
    
    return percentiles, latencies


def generate_comparison_chart(results_dir, test_type, output_file):
    """Generate a comparison chart for all configurations"""
    plt.figure(figsize=(14, 8))
    
    # Determine title, endpoint, and percentile range based on test type
    if test_type == 'simple':
        title = 'Extreme Tail Latency (P99.9 to P99.9999) - Simple JSON Endpoint'
        endpoint = '/json'
        min_percentile = 99.9  # Focus on P99.9+ for simple endpoint (the "nines")
        xlim_min = 99.9
    else:
        title = 'Extreme Tail Latency (P99.9 to P99.9999) - CPU-Intensive Endpoint'
        endpoint = '/waitWithPrimeFactor'
        min_percentile = 99.9  # Focus on P99.9+ for CPU-intensive endpoint (the "nines")
        xlim_min = 99.9
    
    found_data = False
    
    # Plot each configuration
    for config in CONFIGS:
        file_path = results_dir / f"{config}_{test_type}.txt"
        
        if not file_path.exists():
            print(f"  ⚠️  Skipping {config}: file not found")
            continue
        
        percentiles, latencies = parse_wrk_output(file_path, min_percentile)
        
        if not percentiles or not latencies:
            print(f"  ⚠️  Skipping {config}: no data found")
            continue
        
        # Plot the data
        plt.plot(percentiles, latencies, 
                label=CONFIG_LABELS[config],
                color=CONFIG_COLORS[config],
                linewidth=2,
                marker='',
                alpha=0.8)
        
        print(f"  ✅ Plotted {config}: {len(percentiles)} data points")
        found_data = True
    
    if not found_data:
        print(f"  ❌ No data found for {test_type} endpoint")
        plt.close()
        return False
    
    # Customize the plot
    plt.xlabel('Percentile (%)', fontsize=12, fontweight='bold')
    plt.ylabel('Latency (milliseconds)', fontsize=12, fontweight='bold')
    plt.title(title, fontsize=14, fontweight='bold', pad=20)
    plt.grid(True, alpha=0.3, linestyle='--')
    plt.legend(loc='upper left', fontsize=11, framealpha=0.9)
    
    # Focus on tail latencies with appropriate range for test type
    plt.xlim(xlim_min, 100)
    
    # Add custom ticks to highlight the "nines" (P99.9, P99.99, P99.999, P99.9999)
    custom_ticks = [99.9, 99.99, 99.999, 99.9999, 100.0]
    plt.xticks(custom_ticks, ['99.9%', '99.99%', '99.999%', '99.9999%', '100%'])
    
    # Add subtitle with endpoint info
    plt.text(0.5, -0.12, f'Endpoint: {endpoint}',
             ha='center', va='top',
             transform=plt.gca().transAxes,
             fontsize=10, style='italic', color='gray')
    
    # Tight layout
    plt.tight_layout()
    
    # Save the chart
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"  📸 Chart saved: {output_file}")
    return True


def extract_summary_stats(file_path):
    """Extract summary statistics from wrk output"""
    stats = {}
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Extract key metrics
    patterns = {
        'requests_sec': r'Requests/sec:\s+([\d.]+)',
        'latency_avg': r'Latency\s+([^\s]+)',
        'latency_max': r'Latency.*Max\s+([^\s]+)',
        'p50': r'50\.000%\s+([\d.]+)',
        'p75': r'75\.000%\s+([\d.]+)',
        'p90': r'90\.000%\s+([\d.]+)',
        'p99': r'99\.000%\s+([\d.]+)',
        'p999': r'99\.900%\s+([\d.]+)',
    }
    
    for key, pattern in patterns.items():
        match = re.search(pattern, content)
        if match:
            stats[key] = match.group(1)
    
    return stats


def generate_summary_table(results_dir, output_file):
    """Generate a summary comparison table"""
    with open(output_file, 'w') as f:
        f.write("# Benchmark Summary\n\n")
        
        for test_type in ['simple', 'cpu']:
            endpoint = '/json' if test_type == 'simple' else '/waitWithPrimeFactor'
            f.write(f"\n## {endpoint}\n\n")
            f.write("| Config | Req/sec | Avg Latency | P50 | P90 | P99 | P99.9 |\n")
            f.write("|--------|---------|-------------|-----|-----|-----|-------|\n")
            
            for config in CONFIGS:
                file_path = results_dir / f"{config}_{test_type}.txt"
                
                if not file_path.exists():
                    f.write(f"| {CONFIG_LABELS[config]} | N/A | N/A | N/A | N/A | N/A | N/A |\n")
                    continue
                
                stats = extract_summary_stats(file_path)
                f.write(f"| {CONFIG_LABELS[config]} | "
                       f"{stats.get('requests_sec', 'N/A')} | "
                       f"{stats.get('latency_avg', 'N/A')} | "
                       f"{stats.get('p50', 'N/A')}ms | "
                       f"{stats.get('p90', 'N/A')}ms | "
                       f"{stats.get('p99', 'N/A')}ms | "
                       f"{stats.get('p999', 'N/A')}ms |\n")
        
        f.write("\n---\n")
        f.write(f"\n*Generated: {Path(results_dir).name}*\n")


def main():
    """Main function"""
    print("=" * 50)
    print("HdrHistogram Chart Generator (Python)")
    print("=" * 50)
    print()
    
    # Get results directory from command line
    if len(sys.argv) < 2:
        print("❌ Error: No results directory specified")
        print("Usage: python3 generate_charts.py <results-directory>")
        sys.exit(1)
    
    results_dir = Path(sys.argv[1])
    
    if not results_dir.exists():
        print(f"❌ Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    print(f"📁 Results directory: {results_dir}")
    
    # Create output directory
    output_dir = results_dir / 'charts'
    output_dir.mkdir(exist_ok=True)
    print(f"📁 Output directory: {output_dir}")
    print()
    
    # Generate charts for each test type
    success_count = 0
    
    for test_type in ['simple', 'cpu']:
        endpoint = 'Simple JSON' if test_type == 'simple' else 'CPU-Intensive'
        output_file = output_dir / f"comparison_{test_type}.png"
        
        print(f"📈 Generating chart for: {endpoint} endpoint")
        
        if generate_comparison_chart(results_dir, test_type, output_file):
            success_count += 1
        
        print()
    
    # Generate summary table
    summary_file = output_dir / 'summary.md'
    print(f"📊 Generating summary table: {summary_file}")
    generate_summary_table(results_dir, summary_file)
    print(f"  ✅ Summary saved")
    print()
    
    # Final summary
    print("=" * 50)
    if success_count > 0:
        print(f"✅ Chart generation complete!")
        print()
        print(f"📁 Charts saved in: {output_dir}")
        print()
        print(f"Generated files:")
        if (output_dir / 'comparison_simple.png').exists():
            print(f"  - comparison_simple.png (Simple JSON endpoint)")
        if (output_dir / 'comparison_cpu.png').exists():
            print(f"  - comparison_cpu.png (CPU-intensive endpoint)")
        print(f"  - summary.md (Summary statistics)")
        print()
        print(f"View charts: open {output_dir}/")
    else:
        print("❌ No charts were generated")
        sys.exit(1)
    print("=" * 50)


if __name__ == '__main__':
    main()
