#!/bin/bash
#
# ESG Framework Scraper - Run for All Companies
# ==============================================
# This script reads all companies from companies_list.txt and runs
# the ESG framework scraper for each company.
#
# Features:
#   - Parallel scraping with 5 workers (optimized for speed)
#   - Validation with gemini-2.5-pro
#   - Reduced delay (0.3s) for faster execution
#   - Individual JSON output per company
#   - Progress tracking and error logging
#
# Usage:
#   ./run_all_companies.sh                        # Auto-resume from last position
#   ./run_all_companies.sh --resume               # Explicitly resume from last position
#   ./run_all_companies.sh --start 100 --end 200  # Process companies 100-200
#   ./run_all_companies.sh --no-validate          # Skip validation (faster)
#   ./run_all_companies.sh --reset                # Reset progress and start fresh
#

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PYTHON="$PROJECT_ROOT/.venv/bin/python"
SCRAPER_SCRIPT="$SCRIPT_DIR/esg_framework_scraper.py"
COMPANIES_FILE="$SCRIPT_DIR/companies_list.txt"
REPORTS_DIR="$SCRIPT_DIR/reports"
LOG_FILE="$SCRIPT_DIR/scraper.log"
FRAMEWORK_XLSX="$PROJECT_ROOT/esg scoring framework.xlsx"
PROGRESS_TRACKER="$SCRIPT_DIR/progress_tracker.py"
PROGRESS_FILE="$SCRIPT_DIR/scraper_progress.json"

# Scraper settings (optimized for speed)
WORKERS=5
DELAY=0.3
SCRAPE_MODEL="gemini-2.5-flash"
VALIDATE_MODEL="gemini-2.5-pro"
VALIDATE_FLAG=""

# Credentials
export GOOGLE_APPLICATION_CREDENTIALS="$SCRIPT_DIR/credentials/quiet-mechanic-451307-s9-1bd5db312124.json"

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

START_INDEX=0  # 0 means auto-resume
END_INDEX=-1
SKIP_EXISTING=true
AUTO_RESUME=true
RESET_PROGRESS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --start)
            START_INDEX="$2"
            AUTO_RESUME=false
            shift 2
            ;;
        --end)
            END_INDEX="$2"
            shift 2
            ;;
        --resume)
            AUTO_RESUME=true
            START_INDEX=0
            shift
            ;;
        --reset)
            RESET_PROGRESS=true
            shift
            ;;
        --no-validate)
            VALIDATE_FLAG="--no-validate"
            shift
            ;;
        --force)
            SKIP_EXISTING=false
            shift
            ;;
        --workers)
            WORKERS="$2"
            shift 2
            ;;
        --delay)
            DELAY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --resume           Resume from last processed company (default)"
            echo "  --start N          Start from company N (overrides resume)"
            echo "  --end N            Process until company N (default: all)"
            echo "  --reset            Reset progress and start fresh"
            echo "  --no-validate      Skip validation stage (faster)"
            echo "  --force            Reprocess existing reports"
            echo "  --workers N        Number of parallel workers (default: 5)"
            echo "  --delay SECONDS    Delay between API calls (default: 0.3)"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Progress Management:"
            echo "  python3 progress_tracker.py summary    # Show progress"
            echo "  python3 progress_tracker.py failed     # List failed companies"
            echo "  python3 progress_tracker.py reset      # Reset progress"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# VALIDATION
# ============================================================================

if [[ ! -f "$VENV_PYTHON" ]]; then
    echo "ERROR: Virtual environment not found at $VENV_PYTHON"
    echo "Please create a virtual environment first:"
    echo "  python3 -m venv $PROJECT_ROOT/.venv"
    echo "  source $PROJECT_ROOT/.venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

if [[ ! -f "$SCRAPER_SCRIPT" ]]; then
    echo "ERROR: Scraper script not found at $SCRAPER_SCRIPT"
    exit 1
fi

if [[ ! -f "$COMPANIES_FILE" ]]; then
    echo "ERROR: Companies list not found at $COMPANIES_FILE"
    echo "Run: python3 extract_companies.py"
    exit 1
fi

if [[ ! -f "$FRAMEWORK_XLSX" ]]; then
    echo "ERROR: Framework XLSX not found at $FRAMEWORK_XLSX"
    exit 1
fi

if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    echo "ERROR: GCP credentials not found at $GOOGLE_APPLICATION_CREDENTIALS"
    exit 1
fi

# Create reports directory
mkdir -p "$REPORTS_DIR"

# ============================================================================
# PROGRESS TRACKING SETUP
# ============================================================================

# Reset progress if requested
if $RESET_PROGRESS; then
    echo "Resetting progress..."
    "$VENV_PYTHON" "$PROGRESS_TRACKER" reset <<< "yes"
    echo ""
fi

# Show current progress
if [[ -f "$PROGRESS_FILE" ]] && [[ $START_INDEX -eq 0 ]]; then
    echo "Current Progress:"
    "$VENV_PYTHON" "$PROGRESS_TRACKER" summary
fi

# Auto-resume: get last processed index
if [[ $START_INDEX -eq 0 ]] && $AUTO_RESUME; then
    if [[ -f "$PROGRESS_FILE" ]]; then
        RESUME_INDEX=$("$VENV_PYTHON" -c "
import json
with open('$PROGRESS_FILE', 'r') as f:
    data = json.load(f)
    print(data.get('last_processed_index', 0) + 1)
")
        START_INDEX=$RESUME_INDEX
        echo "🔄 AUTO-RESUME: Starting from company #$START_INDEX"
        echo ""
    else
        START_INDEX=1
        echo "📝 NEW SESSION: Starting from beginning"
        echo ""
    fi
elif [[ $START_INDEX -eq 0 ]]; then
    START_INDEX=1
fi

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "========================================================================"
echo "  ESG Framework Scraper - Batch Processing"
echo "========================================================================"
echo "  Project Root    : $PROJECT_ROOT"
echo "  Companies File  : $COMPANIES_FILE"
echo "  Reports Dir     : $REPORTS_DIR"
echo "  Framework XLSX  : $FRAMEWORK_XLSX"
echo "  Workers         : $WORKERS"
echo "  Delay           : ${DELAY}s"
echo "  Validation      : $([ -z "$VALIDATE_FLAG" ] && echo "ENABLED" || echo "DISABLED")"
echo "  Start Index     : $START_INDEX"
echo "  End Index       : $([ $END_INDEX -eq -1 ] && echo "ALL" || echo "$END_INDEX")"
echo "  Skip Existing   : $SKIP_EXISTING"
echo "========================================================================"
echo ""

# Read companies into array
mapfile -t COMPANIES < "$COMPANIES_FILE"
TOTAL_COMPANIES=${#COMPANIES[@]}

if [[ $END_INDEX -eq -1 ]]; then
    END_INDEX=$TOTAL_COMPANIES
fi

# Validate indices
if [[ $START_INDEX -lt 1 ]] || [[ $START_INDEX -gt $TOTAL_COMPANIES ]]; then
    echo "ERROR: Invalid start index $START_INDEX (must be 1-$TOTAL_COMPANIES)"
    exit 1
fi

if [[ $END_INDEX -lt $START_INDEX ]] || [[ $END_INDEX -gt $TOTAL_COMPANIES ]]; then
    echo "ERROR: Invalid end index $END_INDEX (must be $START_INDEX-$TOTAL_COMPANIES)"
    exit 1
fi

PROCESS_COUNT=$((END_INDEX - START_INDEX + 1))
echo "Processing $PROCESS_COUNT companies (${START_INDEX}-${END_INDEX} of $TOTAL_COMPANIES)"
echo ""

# Initialize session in progress tracker
"$VENV_PYTHON" -c "
from progress_tracker import ProgressTracker
tracker = ProgressTracker()
tracker.start_new_session($TOTAL_COMPANIES)
"

# Initialize counters
PROCESSED=0
SKIPPED=0
FAILED=0
START_TIME=$(date +%s)

# Clear log file
> "$LOG_FILE"

# Process each company
for ((i=START_INDEX-1; i<END_INDEX; i++)); do
    COMPANY="${COMPANIES[$i]}"
    INDEX=$((i + 1))
    
    # Sanitize company name for filename
    SAFE_NAME=$(echo "$COMPANY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//')
    OUTPUT_FILE="$REPORTS_DIR/${SAFE_NAME}_esg.json"
    
    # Skip if already exists
    if [[ -f "$OUTPUT_FILE" ]] && $SKIP_EXISTING; then
        echo "[$INDEX/$TOTAL_COMPANIES] SKIP: $COMPANY (already exists)"
        SKIPPED=$((SKIPPED + 1))
        
        # Mark as skipped in progress tracker
        "$VENV_PYTHON" -c "
from progress_tracker import ProgressTracker
tracker = ProgressTracker()
tracker.mark_skipped('$COMPANY', $INDEX)
"
        continue
    fi
    
    echo "========================================================================"
    echo "[$INDEX/$TOTAL_COMPANIES] Processing: $COMPANY"
    echo "========================================================================"
    
    # Run scraper
    if "$VENV_PYTHON" "$SCRAPER_SCRIPT" \
        --company "$COMPANY" \
        --output "$OUTPUT_FILE" \
        --framework-xlsx "$FRAMEWORK_XLSX" \
        --scrape-model "$SCRAPE_MODEL" \
        --validate-model "$VALIDATE_MODEL" \
        --workers "$WORKERS" \
        --delay "$DELAY" \
        $VALIDATE_FLAG \
        2>&1 | tee -a "$LOG_FILE"; then
        
        PROCESSED=$((PROCESSED + 1))
        echo "✓ SUCCESS: $COMPANY → $OUTPUT_FILE"
        
        # Mark as processed in progress tracker
        "$VENV_PYTHON" -c "
from progress_tracker import ProgressTracker
tracker = ProgressTracker()
tracker.mark_processed('$COMPANY', $INDEX, '$OUTPUT_FILE', True)
"
    else
        FAILED=$((FAILED + 1))
        echo "✗ FAILED: $COMPANY (see $LOG_FILE for details)"
        echo "FAILED: $COMPANY" >> "$SCRIPT_DIR/failed_companies.txt"
        
        # Mark as failed in progress tracker
        "$VENV_PYTHON" -c "
from progress_tracker import ProgressTracker
tracker = ProgressTracker()
tracker.mark_processed('$COMPANY', $INDEX, '$OUTPUT_FILE', False)
"
    fi
    
    echo ""
    
    # Progress summary
    ELAPSED=$(($(date +%s) - START_TIME))
    REMAINING=$((PROCESS_COUNT - PROCESSED - SKIPPED - FAILED))
    if [[ $PROCESSED -gt 0 ]]; then
        AVG_TIME=$((ELAPSED / (PROCESSED + FAILED)))
        ETA=$((AVG_TIME * REMAINING))
        echo "Progress: $PROCESSED processed, $SKIPPED skipped, $FAILED failed, $REMAINING remaining"
        echo "Elapsed: ${ELAPSED}s | Avg: ${AVG_TIME}s/company | ETA: ${ETA}s (~$((ETA / 60))m)"
    fi
    echo ""
done

# ============================================================================
# FINAL SUMMARY
# ============================================================================

# End session in progress tracker
"$VENV_PYTHON" -c "
from progress_tracker import ProgressTracker
tracker = ProgressTracker()
tracker.end_session()
"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo "========================================================================"
echo "  BATCH PROCESSING COMPLETE"
echo "========================================================================"
echo "  Total Companies : $PROCESS_COUNT"
echo "  Processed       : $PROCESSED"
echo "  Skipped         : $SKIPPED"
echo "  Failed          : $FAILED"
echo "  Total Time      : ${TOTAL_TIME}s (~$((TOTAL_TIME / 60))m)"
echo "  Reports Dir     : $REPORTS_DIR"
echo "  Log File        : $LOG_FILE"
echo "========================================================================"

# Show final progress
echo ""
"$VENV_PYTHON" "$PROGRESS_TRACKER" summary

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo "⚠ Some companies failed. Check:"
    echo "  - $LOG_FILE"
    echo "  - $SCRIPT_DIR/failed_companies.txt"
    echo ""
    echo "To retry failed companies:"
    echo "  python3 progress_tracker.py failed"
    exit 1
fi

echo ""
echo "✓ All companies processed successfully!"
echo ""
echo "To resume later if interrupted:"
echo "  ./run_all_companies.sh --resume"
exit 0
