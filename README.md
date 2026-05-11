# ESG Framework Scraper

Automated ESG data extraction and validation system for all companies in the database.

## 🎯 Features

- **Multi-Framework Coverage**: BRSR, CDP (Climate/Water/Forests), GRI, Ecovadis, DJSI, S&P CSA, OSHA, Greenco
- **Intelligent Scraping**: Question-aware resource mapping with semantic extraction
- **Validation Agent**: gemini-2.5-pro validates all scraped data for accuracy
- **Resume Capability**: Auto-resume from last processed company if interrupted
- **Progress Tracking**: Real-time progress monitoring and session history
- **Parallel Processing**: 5 workers for fast scraping (configurable)
- **Final Scoring**: E/S/G scores + Overall ESG score with maturity profile

## 📁 Folder Structure

```
esg_scraper/
├── credentials/
│   └── quiet-mechanic-451307-s9-1bd5db312124.json  # GCP service account
├── reports/
│   └── [company_name]_esg.json                      # Output reports
├── esg_framework_scraper.py                         # Main scraper
├── progress_tracker.py                              # Progress management
├── extract_companies.py                             # Company list extractor
├── companies_list.txt                               # All companies (1821)
├── start_scraper.sh                                 # Quick start wrapper
├── run_all_companies.sh                             # Main batch script
├── scraper_progress.json                            # Progress state
├── scraper.log                                      # Execution log
└── README.md                                        # This file
```

## 🚀 Quick Start

### 1. Setup (First Time Only)

```bash
# Ensure virtual environment is set up
cd /home/brsrk94/Videos/README
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Run Scraper

```bash
cd esg_scraper

# Auto-resume from last position (default)
./start_scraper.sh

# Start fresh (reset progress)
./start_scraper.sh --fresh

# Fast mode (skip validation)
./start_scraper.sh --fast

# Test mode (first 5 companies)
./start_scraper.sh --test
```

### 3. Monitor Progress

```bash
# Show current progress
./start_scraper.sh --status

# Show failed companies
./start_scraper.sh --failed

# Or use progress tracker directly
python3 progress_tracker.py summary
python3 progress_tracker.py failed
```

## 📊 Progress Management

The scraper automatically tracks progress and can resume from where it stopped:

```bash
# View progress summary
python3 progress_tracker.py summary

# Output:
# ========================================================================
#   SCRAPER PROGRESS SUMMARY
# ========================================================================
#   Total Companies    : 1821
#   Processed          : 150 ✓
#   Failed             : 5 ✗
#   Skipped            : 0 ⊘
#   Remaining          : 1666
#   Completion         : 8.51%
#   Last Processed     : Tata Steel
#   Resume From Index  : 151
# ========================================================================
```

### Resume After Interruption

If the scraper is interrupted (Ctrl+C, system crash, network issue), simply restart:

```bash
./start_scraper.sh
# Automatically resumes from company #151
```

### Reset Progress

To start from scratch:

```bash
python3 progress_tracker.py reset
# Or
./start_scraper.sh --fresh
```

## ⚙️ Advanced Usage

### Custom Range

```bash
# Process companies 100-200
./run_all_companies.sh --start 100 --end 200

# Process from 500 to end
./run_all_companies.sh --start 500
```

### Performance Tuning

```bash
# Increase workers (faster but more API load)
./run_all_companies.sh --workers 10 --delay 0.2

# Decrease workers (slower but safer)
./run_all_companies.sh --workers 3 --delay 0.5
```

### Skip Validation (Faster)

```bash
# Skip validation stage (2x faster)
./run_all_companies.sh --no-validate
```

### Force Reprocess

```bash
# Reprocess even if report exists
./run_all_companies.sh --force
```

## 📋 Output Format

Each company gets a JSON report with:

```json
{
  "company_name": "Tata Steel",
  "timestamp": "2026-05-11T10:30:00",
  "scrape_model": "gemini-2.5-flash",
  "validation_model": "gemini-2.5-pro",
  "validation_enabled": true,
  
  "final_scores": {
    "environmental_score": {
      "label": "Environmental (E)",
      "raw_score": 95.5,
      "max_raw_score": 130,
      "percentage": 73.46,
      "normalized_score": 95.5,
      "framework_max": 130,
      "weight": "40%"
    },
    "social_score": {
      "label": "Social (S)",
      "raw_score": 120.3,
      "max_raw_score": 148,
      "percentage": 81.28,
      "normalized_score": 120.3,
      "framework_max": 148,
      "weight": "35%"
    },
    "governance_score": {
      "label": "Governance (G)",
      "raw_score": 65.2,
      "max_raw_score": 79,
      "percentage": 82.53,
      "normalized_score": 65.2,
      "framework_max": 79,
      "weight": "25%"
    },
    "overall_esg_score": {
      "label": "Overall ESG Score",
      "score": 78.45,
      "out_of": 100,
      "profile": "Advanced",
      "formula": "[(40%xE + 35%xS + 25%xG) / (40%x130 + 35%x148 + 25%x79)] x 100"
    }
  },
  
  "framework_scoring": {
    "Environment": {
      "esg_category": "Environmental",
      "questions": [...],
      "total_achieved_score": 95.5,
      "total_max_score": 130,
      "pillar_percentage": 73.46
    },
    "Social": {...},
    "Governance": {...}
  },
  
  "validation_summary": {
    "confirmed": 245,
    "corrected": 12,
    "flagged": 3,
    "invalid": 2,
    "total": 262
  },
  
  "data_sources_searched": [
    "https://www.tatasteel.com/sustainability/brsr-2024.pdf",
    "https://www.cdp.net/en/responses/12345",
    ...
  ]
}
```

## 🔧 Troubleshooting

### Scraper Fails to Start

```bash
# Check virtual environment
source ../.venv/bin/activate
pip install -r ../requirements.txt

# Check credentials
ls -la credentials/quiet-mechanic-451307-s9-1bd5db312124.json

# Check framework file
ls -la "../esg scoring framework.xlsx"
```

### High Failure Rate

```bash
# View failed companies
python3 progress_tracker.py failed

# Check logs
tail -f scraper.log

# Reduce workers and increase delay
./run_all_companies.sh --workers 3 --delay 0.5
```

### Out of Memory

```bash
# Reduce workers
./run_all_companies.sh --workers 2

# Process in batches
./run_all_companies.sh --start 1 --end 500
./run_all_companies.sh --start 501 --end 1000
./run_all_companies.sh --start 1001
```

## 📈 Performance Estimates

- **With Validation**: ~2-3 minutes per company
- **Without Validation**: ~1-1.5 minutes per company
- **Total Time (1821 companies)**:
  - With validation: ~60-90 hours
  - Without validation: ~30-45 hours

**Recommendation**: Run in batches or use `--no-validate` for initial pass, then validate critical companies separately.

## 🛡️ Safety Features

1. **Auto-save Progress**: Progress saved after each company
2. **Resume Capability**: Never lose work if interrupted
3. **Skip Existing**: Won't reprocess unless `--force`
4. **Error Logging**: All errors logged to `scraper.log`
5. **Failed Tracking**: Failed companies tracked separately

## 📞 Support

For issues or questions:
1. Check `scraper.log` for errors
2. Run `python3 progress_tracker.py summary` for status
3. Review failed companies with `python3 progress_tracker.py failed`

## 🎯 Next Steps

After scraping completes:
1. Review validation summary in each report
2. Check failed companies and retry if needed
3. Aggregate scores across all companies
4. Generate comparative analysis reports
