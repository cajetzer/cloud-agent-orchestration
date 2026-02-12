#!/usr/bin/env python3
"""
Script to organize pipeline file into correct directory structure.
Run this to complete the pipeline setup.
"""

import os
import shutil
from pathlib import Path

def main():
    # Get the repository root (where this script is located)
    repo_root = Path(__file__).parent
    
    # Define source and destination
    source_file = repo_root / "copy_blob_to_sql_sales.json"
    dest_dir = repo_root / "pipelines"
    dest_file = dest_dir / "copy_blob_to_sql_sales.json"
    
    # Create pipelines directory if it doesn't exist
    dest_dir.mkdir(exist_ok=True)
    print(f"✓ Created directory: {dest_dir}")
    
    # Move the pipeline file
    if source_file.exists():
        shutil.move(str(source_file), str(dest_file))
        print(f"✓ Moved pipeline file to: {dest_file}")
        print("\nSuccess! The pipeline file is now in the correct location.")
        print("Next steps:")
        print("  1. git add -A")
        print("  2. git commit -m 'Move pipeline to pipelines directory'")
        print("  3. git push")
    else:
        print(f"✗ Error: Source file not found: {source_file}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
