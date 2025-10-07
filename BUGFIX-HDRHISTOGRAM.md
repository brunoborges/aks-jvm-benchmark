# 🐛 Bug Fix: HdrHistogram Chart Generation

## Problem

The chart generation failed with errors:
- **comparison_cpu.png**: "Data column(s) for axis #0 cannot be of type string"
- **comparison_simple.png**: Empty chart with negative latency axis

**Root Cause:** The `.hdr` files were not in the correct CSV format expected by the HdrHistogram plotter website.

## What Was Wrong

### Before (Incorrect Format)
```
   10280.959     0.000000            1         1.00
   26558.463     0.100000          180         1.11
```
- No CSV header
- Space-separated values
- Missing timestamp metadata
- HdrHistogram plotter couldn't parse it

### After (Correct Format)
```
#[StartTime: 0 (seconds), 1759819877]
#[BaseTime: 0.0 (seconds)]
Value,Percentile,TotalCount,1/(1-Percentile)
0.144,0.000000,1,1.00
0.503,0.100000,51071,1.11
0.643,0.200000,102069,1.25
```
- Proper CSV header with column names
- Comma-separated values
- Timestamp metadata
- Compatible with HdrHistogram plotter

## Solution

### 1. Fixed `extract_hdr_data()` Function

Updated `run-redistribution-benchmark.sh` to generate proper CSV format:

```bash
extract_hdr_data() {
    local input_file=$1
    local output_file=$2
    
    # Create HdrHistogram header (CSV format)
    echo "#[StartTime: 0 (seconds), $(date +%s)]" > "$output_file"
    echo "#[BaseTime: 0.0 (seconds)]" >> "$output_file"
    echo "Value,Percentile,TotalCount,1/(1-Percentile)" >> "$output_file"
    
    # Extract from wrk -L output (values already in milliseconds)
    awk '/Detailed Percentile spectrum:/,/#\[Mean/{
        if ($1 ~ /^[0-9]+\.[0-9]+$/ && NF == 4) {
            printf "%s,%s,%s,%s\n", $1, $2, $3, $4
        }
    }' "$input_file" >> "$output_file"
}
```

**Key changes:**
- ✅ Added proper CSV header with column names
- ✅ Added timestamp metadata (`#[StartTime]`, `#[BaseTime]`)
- ✅ Changed output to comma-separated values
- ✅ Kept values in milliseconds (wrk already outputs in ms)
- ✅ Improved awk pattern to match wrk output format

### 2. Regenerated Existing Files

For existing benchmark results, run this to regenerate `.hdr` files:

```bash
RESULTS_DIR="benchmark-results/20251007-021703"

for txt_file in "$RESULTS_DIR"/*.txt; do
    base_name=$(basename "$txt_file" .txt)
    hdr_file="$RESULTS_DIR/${base_name}.hdr"
    
    # Create CSV header
    echo "#[StartTime: 0 (seconds), $(date +%s)]" > "$hdr_file"
    echo "#[BaseTime: 0.0 (seconds)]" >> "$hdr_file"
    echo "Value,Percentile,TotalCount,1/(1-Percentile)" >> "$hdr_file"
    
    # Extract data
    awk '/Detailed Percentile spectrum:/,/#\[Mean/{
        if ($1 ~ /^[0-9]+\.[0-9]+$/ && NF == 4) {
            printf "%s,%s,%s,%s\n", $1, $2, $3, $4
        }
    }' "$txt_file" >> "$hdr_file"
done
```

## Verification

### Check File Format
```bash
head -5 benchmark-results/20251007-021703/2by2_simple.hdr
```

Expected output:
```
#[StartTime: 0 (seconds), 1759819877]
#[BaseTime: 0.0 (seconds)]
Value,Percentile,TotalCount,1/(1-Percentile)
0.144,0.000000,1,1.00
0.503,0.100000,51071,1.11
```

### Regenerate Charts
```bash
./generate-charts.sh benchmark-results/20251007-021703
```

Should succeed with:
```
✅ Uploaded 6by1
✅ Uploaded 3by2
✅ Uploaded 2by3
✅ Uploaded 2by2
📸 Chart saved: comparison_simple.png
📸 Chart saved: comparison_cpu.png
```

### View Charts
```bash
open benchmark-results/20251007-021703/charts/
```

Charts should now display properly with:
- ✅ All 4 configurations visible
- ✅ Proper latency axes (positive values)
- ✅ Percentile distribution curves
- ✅ Legend showing 6by1, 3by2, 2by3, 2by2

## Technical Details

### wrk -L Output Format

The `wrk` tool with `-L` flag outputs:
```
Detailed Percentile spectrum:
     Value   Percentile   TotalCount 1/(1-Percentile)

     0.144     0.000000            1         1.00
     0.503     0.100000        51071         1.11
```

- **Value**: Latency in milliseconds (not microseconds!)
- **Percentile**: Decimal (0.0 to 1.0)
- **TotalCount**: Cumulative request count
- **1/(1-Percentile)**: Inverse percentile

### HdrHistogram Plotter Format

The web plotter at http://hdrhistogram.github.io/HdrHistogram/plotFiles.html expects:

1. **Metadata comments** (optional but recommended):
   ```
   #[StartTime: 0 (seconds), <timestamp>]
   #[BaseTime: 0.0 (seconds)]
   ```

2. **CSV header** (required):
   ```
   Value,Percentile,TotalCount,1/(1-Percentile)
   ```

3. **Data rows** (comma-separated):
   ```
   0.144,0.000000,1,1.00
   0.503,0.100000,51071,1.11
   ```

## Files Changed

- ✅ `run-redistribution-benchmark.sh` - Fixed `extract_hdr_data()` function
- ✅ All `.hdr` files in `benchmark-results/20251007-021703/` - Regenerated

## Impact

- ✅ **Charts now generate correctly** with all 4 configurations
- ✅ **Latency percentiles displayed properly** in HdrHistogram format
- ✅ **Future benchmarks** will automatically generate correct format
- ✅ **Existing results** can be regenerated using the script above

## Future Benchmarks

The fix is already in `run-redistribution-benchmark.sh`, so:
- ✅ New benchmarks will automatically create correct `.hdr` files
- ✅ Chart generation will work without manual intervention
- ✅ No additional steps needed

---

**Date Fixed:** October 7, 2025  
**Issue:** Incorrect HdrHistogram file format prevented chart generation  
**Status:** ✅ **RESOLVED**
