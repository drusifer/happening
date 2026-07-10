#!/usr/bin/env python
"""
fetch_cities — Cross-platform utility to download and parse GeoNames database.

TLDR:
    Downloads cities15000 database from geonames.org, extracts the raw dataset,
    processes it in UTF-8 format to format name|country|lat|lng, and saves the
    result to `app/assets/data/cities.csv`.
    Key functions: main() orchestrates download, unzip, and write processes.

"""

import sys
import os
import urllib.request
import zipfile
import tempfile
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────────────

CITIES_URL = "https://download.geonames.org/export/dump/cities15000.zip"

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
OUTPUT_CSV = PROJECT_ROOT / 'app' / 'assets' / 'data' / 'cities.csv'

# ── Main Process ─────────────────────────────────────────────────────────────

def main():
    print("Downloading GeoNames cities15000 database...")
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)

    # Use a secure temporary directory for download and extraction
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_zip = Path(temp_dir) / "cities15000.zip"
        
        try:
            # Download file
            urllib.request.urlretrieve(CITIES_URL, temp_zip)
            print("✓ Database zip downloaded successfully.")
        except Exception as e:
            print(f"Error downloading database: {e}", file=sys.stderr)
            sys.exit(1)

        # Unzip the TXT file
        print("Extracting dataset...")
        try:
            with zipfile.ZipFile(temp_zip, 'r') as zip_ref:
                zip_ref.extract("cities15000.txt", temp_dir)
            temp_txt = Path(temp_dir) / "cities15000.txt"
            print("✓ Dataset extracted successfully.")
        except Exception as e:
            print(f"Error extracting dataset: {e}", file=sys.stderr)
            sys.exit(1)

        # Process and write the data
        print("Processing: name|country|lat|lng ...")
        cities_count = 0
        try:
            with open(temp_txt, 'r', encoding='utf-8') as infile, \
                 open(OUTPUT_CSV, 'w', encoding='utf-8', newline='') as outfile:
                
                for line in infile:
                    fields = line.strip().split('\t')
                    if len(fields) >= 9:
                        asciiname = fields[2]
                        country = fields[8]
                        lat = fields[4]
                        lng = fields[5]

                        # Clean any pipes from names to prevent delimiter pollution (like gsub(/\|/," ",name))
                        asciiname = asciiname.replace('|', ' ')

                        outfile.write(f"{asciiname}|{country}|{lat}|{lng}\n")
                        cities_count += 1
            print(f"[OK] Done: {OUTPUT_CSV} ({cities_count} cities)")
        except Exception as e:
            print(f"Error processing dataset: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
