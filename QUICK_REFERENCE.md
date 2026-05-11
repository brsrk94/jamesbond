# ESG Scraper - Quick Reference Card

## 🚀 Most Common Commands

```bash
# Start/Resume scraping (auto-resumes from last position)
./start_scraper.sh

# Check progress
./start_scraper.sh --status

# Test with 5 companies
./start_scraper.sh --test

# Start fresh (reset progress)
./start_scraper.sh --fresh

# Fast mode (no validation, 2x faster)
./start_scraper.sh --fast
```

## 📊 Progress Management

```bash
# View detailed progress
python3 progress_tracker.py summary

# List failed companies
python3 progress_tracker.py failed

# Reset all progress
python3 progress_tracker.py reset
```

## 🔧 Advanced Usage

```bash
# Process specific range
./run_all_companies.sh --start 100 --end 200

# Custom workers and delay
./run_all_companies.sh --workers 10 --delay 0.2

# Skip validation (faster)
./run_all_companies.sh --no-validate

# Force reprocess existing reports
./run_all_companies.sh --force
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `start_scraper.sh` | Quick start wrapper |
| `run_all_companies.sh` | Main batch script |
| `progress_tracker.py` | Progress management |
| `scraper_progress.json` | Progress state (auto-created) |
| `scraper.log` | Execution log |
| `reports/*.json` | Output reports |
| `companies_list.txt` | All 1821 companies |

## 🎯 Typical Workflow

### First Time
```bash
# 1. Test setup
./test_setup.sh

# 2. Test with 5 companies
./start_scraper.sh --test

# 3. If test works, start full scraping
./start_scraper.sh
```

### After Interruption
```bash
# Just restart - auto-resumes!
./start_scraper.sh
```

### Check Progress
```bash
# Quick status
./start_scraper.sh --status

# Detailed progress
python3 progress_tracker.py summary
```

## ⚡ Performance Tips

| Mode | Speed | Accuracy | Command |
|------|-------|----------|---------|
| **Standard** | 2-3 min/company | High | `./start_scraper.sh` |
| **Fast** | 1-1.5 min/company | Good | `./start_scraper.sh --fast` |
| **Turbo** | <1 min/company | Good | `./run_all_companies.sh --workers 10 --delay 0.2 --no-validate` |

## 🛡️ Safety Features

✅ **Auto-resume**: Continues from last position  
✅ **Auto-save**: Progress saved after each company  
✅ **Skip existing**: Won't reprocess unless forced  
✅ **Error logging**: All errors logged  
✅ **Failed tracking**: Failed companies tracked separately  

## 📈 Expected Timeline

| Companies | With Validation | Without Validation |
|-----------|----------------|-------------------|
| 5 (test) | 10-15 min | 5-8 min |
| 100 | 3-5 hours | 1.5-2.5 hours |
| 500 | 16-25 hours | 8-12 hours |
| 1821 (all) | 60-90 hours | 30-45 hours |

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| Scraper stops | `./start_scraper.sh` (auto-resumes) |
| High failure rate | `./run_all_companies.sh --workers 3 --delay 0.5` |
| Check errors | `tail -f scraper.log` |
| See failed companies | `./start_scraper.sh --failed` |
| Reset everything | `./start_scraper.sh --fresh` |

## 📞 Help

```bash
# Script help
./start_scraper.sh --help
./run_all_companies.sh --help

# Verify setup
./test_setup.sh

# Full documentation
cat README.md
cat SETUP_COMPLETE.md
```

## 🎯 Output Location

All reports saved to: `reports/[company_name]_esg.json`

Example:
```
reports/
├── tata_steel_esg.json
├── infosys_esg.json
├── reliance_industries_esg.json
└── ...
```

---

**Quick Start**: `./start_scraper.sh --test` → `./start_scraper.sh`  
**Resume**: `./start_scraper.sh` (automatic)  
**Status**: `./start_scraper.sh --status`
