#!/usr/bin/env python3
"""
Progress Tracker for ESG Scraper
=================================
Tracks which companies have been processed and allows resuming from last position.
"""
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

class ProgressTracker:
    """Track scraping progress and enable resume functionality"""
    
    def __init__(self, progress_file: str = "scraper_progress.json"):
        self.progress_file = Path(__file__).parent / progress_file
        self.progress_data = self._load_progress()
    
    def _load_progress(self) -> Dict:
        """Load existing progress or create new"""
        if self.progress_file.exists():
            try:
                with open(self.progress_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Warning: Could not load progress file: {e}")
                return self._init_progress()
        return self._init_progress()
    
    def _init_progress(self) -> Dict:
        """Initialize new progress structure"""
        return {
            "started_at": datetime.now().isoformat(),
            "last_updated": datetime.now().isoformat(),
            "total_companies": 0,
            "processed_count": 0,
            "failed_count": 0,
            "skipped_count": 0,
            "last_processed_index": 0,
            "last_processed_company": None,
            "companies": {},
            "failed_companies": [],
            "session_history": []
        }
    
    def save_progress(self):
        """Save current progress to file"""
        self.progress_data["last_updated"] = datetime.now().isoformat()
        try:
            with open(self.progress_file, 'w', encoding='utf-8') as f:
                json.dump(self.progress_data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Warning: Could not save progress: {e}")
    
    def mark_processed(self, company: str, index: int, output_file: str, success: bool = True):
        """Mark a company as processed"""
        status = "success" if success else "failed"
        
        self.progress_data["companies"][company] = {
            "index": index,
            "status": status,
            "output_file": output_file,
            "processed_at": datetime.now().isoformat()
        }
        
        if success:
            self.progress_data["processed_count"] += 1
        else:
            self.progress_data["failed_count"] += 1
            if company not in self.progress_data["failed_companies"]:
                self.progress_data["failed_companies"].append(company)
        
        self.progress_data["last_processed_index"] = index
        self.progress_data["last_processed_company"] = company
        self.save_progress()
    
    def mark_skipped(self, company: str, index: int):
        """Mark a company as skipped"""
        self.progress_data["companies"][company] = {
            "index": index,
            "status": "skipped",
            "skipped_at": datetime.now().isoformat()
        }
        self.progress_data["skipped_count"] += 1
        self.save_progress()
    
    def is_processed(self, company: str) -> bool:
        """Check if company has been processed"""
        return company in self.progress_data["companies"]
    
    def get_status(self, company: str) -> Optional[str]:
        """Get processing status of a company"""
        if company in self.progress_data["companies"]:
            return self.progress_data["companies"][company].get("status")
        return None
    
    def get_resume_index(self) -> int:
        """Get the index to resume from (1-based)"""
        return self.progress_data["last_processed_index"] + 1
    
    def get_failed_companies(self) -> List[str]:
        """Get list of failed companies"""
        return self.progress_data["failed_companies"]
    
    def start_new_session(self, total_companies: int):
        """Start a new scraping session"""
        session = {
            "started_at": datetime.now().isoformat(),
            "total_companies": total_companies,
            "resume_from": self.get_resume_index()
        }
        self.progress_data["session_history"].append(session)
        self.progress_data["total_companies"] = total_companies
        self.save_progress()
    
    def end_session(self):
        """End current scraping session"""
        if self.progress_data["session_history"]:
            self.progress_data["session_history"][-1]["ended_at"] = datetime.now().isoformat()
            self.progress_data["session_history"][-1]["processed"] = self.progress_data["processed_count"]
            self.progress_data["session_history"][-1]["failed"] = self.progress_data["failed_count"]
            self.save_progress()
    
    def reset_progress(self):
        """Reset all progress (use with caution!)"""
        self.progress_data = self._init_progress()
        self.save_progress()
    
    def get_summary(self) -> Dict:
        """Get progress summary"""
        return {
            "total_companies": self.progress_data["total_companies"],
            "processed": self.progress_data["processed_count"],
            "failed": self.progress_data["failed_count"],
            "skipped": self.progress_data["skipped_count"],
            "remaining": self.progress_data["total_companies"] - 
                        self.progress_data["processed_count"] - 
                        self.progress_data["failed_count"] - 
                        self.progress_data["skipped_count"],
            "last_processed": self.progress_data["last_processed_company"],
            "resume_from_index": self.get_resume_index(),
            "completion_percentage": round(
                (self.progress_data["processed_count"] + 
                 self.progress_data["failed_count"] + 
                 self.progress_data["skipped_count"]) / 
                max(self.progress_data["total_companies"], 1) * 100, 2
            )
        }
    
    def print_summary(self):
        """Print progress summary"""
        summary = self.get_summary()
        print("\n" + "="*72)
        print("  SCRAPER PROGRESS SUMMARY")
        print("="*72)
        print(f"  Total Companies    : {summary['total_companies']}")
        print(f"  Processed          : {summary['processed']} ✓")
        print(f"  Failed             : {summary['failed']} ✗")
        print(f"  Skipped            : {summary['skipped']} ⊘")
        print(f"  Remaining          : {summary['remaining']}")
        print(f"  Completion         : {summary['completion_percentage']}%")
        print(f"  Last Processed     : {summary['last_processed']}")
        print(f"  Resume From Index  : {summary['resume_from_index']}")
        print("="*72 + "\n")


if __name__ == "__main__":
    import sys
    
    tracker = ProgressTracker()
    
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        
        if cmd == "summary":
            tracker.print_summary()
        
        elif cmd == "reset":
            confirm = input("Are you sure you want to reset all progress? (yes/no): ")
            if confirm.lower() == "yes":
                tracker.reset_progress()
                print("✓ Progress reset successfully")
            else:
                print("✗ Reset cancelled")
        
        elif cmd == "failed":
            failed = tracker.get_failed_companies()
            if failed:
                print(f"\nFailed companies ({len(failed)}):")
                for i, company in enumerate(failed, 1):
                    print(f"  {i}. {company}")
            else:
                print("\n✓ No failed companies")
        
        else:
            print(f"Unknown command: {cmd}")
            print("Usage: python3 progress_tracker.py [summary|reset|failed]")
    
    else:
        tracker.print_summary()
