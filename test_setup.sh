#!/bin/bash
#
# Test ESG Scraper Setup
# ======================
# Verify all components are properly configured
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================================================"
echo "  ESG Scraper Setup Verification"
echo "========================================================================"
echo ""

ERRORS=0

# Check 1: Virtual environment
echo "✓ Checking virtual environment..."
if [[ -f "$PROJECT_ROOT/.venv/bin/python" ]]; then
    PYTHON_VERSION=$("$PROJECT_ROOT/.venv/bin/python" --version 2>&1)
    echo "  ✓ Found: $PYTHON_VERSION"
else
    echo "  ✗ Virtual environment not found at $PROJECT_ROOT/.venv"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: Credentials
echo "✓ Checking GCP credentials..."
if [[ -f "$SCRIPT_DIR/credentials/quiet-mechanic-451307-s9-1bd5db312124.json" ]]; then
    echo "  ✓ Found: credentials/quiet-mechanic-451307-s9-1bd5db312124.json"
else
    echo "  ✗ Credentials not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Framework XLSX
echo "✓ Checking framework file..."
if [[ -f "$PROJECT_ROOT/esg scoring framework.xlsx" ]]; then
    SIZE=$(du -h "$PROJECT_ROOT/esg scoring framework.xlsx" | cut -f1)
    echo "  ✓ Found: esg scoring framework.xlsx ($SIZE)"
else
    echo "  ✗ Framework file not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Companies list
echo "✓ Checking companies list..."
if [[ -f "$SCRIPT_DIR/companies_list.txt" ]]; then
    COUNT=$(wc -l < "$SCRIPT_DIR/companies_list.txt")
    echo "  ✓ Found: companies_list.txt ($COUNT companies)"
else
    echo "  ✗ Companies list not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 5: Scripts
echo "✓ Checking scripts..."
SCRIPTS=(
    "esg_framework_scraper.py"
    "progress_tracker.py"
    "extract_companies.py"
    "start_scraper.sh"
    "run_all_companies.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            echo "  ✓ $script (executable)"
        else
            echo "  ⚠ $script (not executable)"
        fi
    else
        echo "  ✗ $script (missing)"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check 6: Python dependencies
echo "✓ Checking Python dependencies..."
if [[ -f "$PROJECT_ROOT/.venv/bin/python" ]]; then
    MISSING_DEPS=()
    
    for pkg in openpyxl google-cloud-aiplatform python-dotenv; do
        if ! "$PROJECT_ROOT/.venv/bin/python" -c "import ${pkg//-/_}" 2>/dev/null; then
            MISSING_DEPS+=("$pkg")
        fi
    done
    
    if [[ ${#MISSING_DEPS[@]} -eq 0 ]]; then
        echo "  ✓ All required packages installed"
    else
        echo "  ⚠ Missing packages: ${MISSING_DEPS[*]}"
        echo "    Run: pip install ${MISSING_DEPS[*]}"
    fi
fi
echo ""

# Check 7: Directories
echo "✓ Checking directories..."
if [[ -d "$SCRIPT_DIR/reports" ]]; then
    echo "  ✓ reports/ directory exists"
else
    echo "  ⚠ reports/ directory missing (will be created)"
    mkdir -p "$SCRIPT_DIR/reports"
fi
echo ""

# Summary
echo "========================================================================"
if [[ $ERRORS -eq 0 ]]; then
    echo "  ✓ ALL CHECKS PASSED"
    echo "========================================================================"
    echo ""
    echo "Ready to start scraping!"
    echo ""
    echo "Quick start:"
    echo "  ./start_scraper.sh --test    # Test with 5 companies"
    echo "  ./start_scraper.sh           # Start full scraping"
    echo ""
else
    echo "  ✗ FOUND $ERRORS ERROR(S)"
    echo "========================================================================"
    echo ""
    echo "Please fix the errors above before running the scraper."
    echo ""
    exit 1
fi
