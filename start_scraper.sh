#!/bin/bash
#
# ESG Scraper - Quick Start Script
# =================================
# Simple wrapper to start the ESG framework scraper with sensible defaults.
#
# Usage:
#   ./start_scraper.sh                    # Auto-resume from last position
#   ./start_scraper.sh --fresh            # Start fresh (reset progress)
#   ./start_scraper.sh --fast             # Fast mode (no validation)
#   ./start_scraper.sh --test             # Test mode (first 5 companies)
#   ./start_scraper.sh --status           # Show current progress
#   ./start_scraper.sh --failed           # Show failed companies
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PYTHON="$PROJECT_ROOT/.venv/bin/python"

# Check if virtual environment exists
if [[ ! -f "$VENV_PYTHON" ]]; then
    echo "ERROR: Virtual environment not found!"
    echo ""
    echo "Please set up the environment first:"
    echo "  cd $PROJECT_ROOT"
    echo "  python3 -m venv .venv"
    echo "  source .venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

# Parse command
case "${1:-resume}" in
    --fresh|fresh)
        echo "🔄 Starting fresh (resetting progress)..."
        "$SCRIPT_DIR/run_all_companies.sh" --reset
        ;;
    
    --fast|fast)
        echo "⚡ Fast mode (no validation)..."
        "$SCRIPT_DIR/run_all_companies.sh" --no-validate
        ;;
    
    --test|test)
        echo "🧪 Test mode (first 5 companies)..."
        "$SCRIPT_DIR/run_all_companies.sh" --start 1 --end 5 --reset
        ;;
    
    --status|status)
        echo "📊 Current Progress:"
        "$VENV_PYTHON" "$SCRIPT_DIR/progress_tracker.py" summary
        ;;
    
    --failed|failed)
        echo "❌ Failed Companies:"
        "$VENV_PYTHON" "$SCRIPT_DIR/progress_tracker.py" failed
        ;;
    
    --resume|resume|"")
        echo "▶️  Resuming from last position..."
        "$SCRIPT_DIR/run_all_companies.sh" --resume
        ;;
    
    --help|-h|help)
        echo "ESG Scraper - Quick Start"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  (default)    Resume from last position"
        echo "  --fresh      Start fresh (reset progress)"
        echo "  --fast       Fast mode (skip validation)"
        echo "  --test       Test mode (first 5 companies)"
        echo "  --status     Show current progress"
        echo "  --failed     Show failed companies"
        echo "  --help       Show this help"
        echo ""
        echo "Advanced usage:"
        echo "  ./run_all_companies.sh --help"
        ;;
    
    *)
        echo "Unknown command: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
