#!/usr/bin/env python3
"""
Extract unique company names from structured-data.json
"""
import json
from pathlib import Path

def extract_companies():
    """Extract unique company names from structured-data.json"""
    data_file = Path(__file__).resolve().parents[1] / "public" / "data" / "structured-data.json"
    
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    companies = []
    seen = set()
    
    for record in data.get('records', []):
        company_name = record.get('company', {}).get('name', '').strip()
        if company_name and company_name not in seen:
            companies.append(company_name)
            seen.add(company_name)
    
    # Sort companies alphabetically
    companies.sort()
    
    return companies

if __name__ == "__main__":
    companies = extract_companies()
    print(f"Total unique companies: {len(companies)}")
    
    # Write to file
    output_file = Path(__file__).parent / "companies_list.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        for company in companies:
            f.write(f"{company}\n")
    
    print(f"Company list saved to: {output_file}")
    print(f"\nFirst 10 companies:")
    for i, c in enumerate(companies[:10], 1):
        print(f"  {i}. {c}")
