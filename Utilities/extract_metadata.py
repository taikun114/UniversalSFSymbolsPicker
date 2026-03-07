#!/usr/bin/env python3
import os
import plistlib
import json
import re
import subprocess
import argparse
import sys

def parse_version(v):
    """Parses a version string into a tuple of integers for comparison."""
    try:
        return tuple(map(int, (re.sub(r'[^0-9.]', '', v).split('.'))))
    except:
        return (0, 0)

def load_plist_or_strings(path):
    """
    Loads a .plist or .strings file using plutil to convert it to XML first.
    """
    try:
        result = subprocess.run(['plutil', '-convert', 'xml1', '-o', '-', path], 
                                capture_output=True, check=True)
        return plistlib.loads(result.stdout)
    except Exception as e:
        print(f"Warning: Failed to load {path}: {e}")
        return None

def get_app_version(app_path):
    """Reads the version of the SF Symbols app from its Info.plist."""
    info_plist_path = os.path.join(app_path, "Contents/Info.plist")
    if os.path.exists(info_plist_path):
        try:
            with open(info_plist_path, 'rb') as f:
                info = plistlib.load(f)
                return info.get("CFBundleShortVersionString", "0.0")
        except:
            pass
    return "0.0"

def get_existing_json_version(file_path):
    """Extracts the bundleVersion from an existing SFSymbolData.json file."""
    if not os.path.exists(file_path):
        return None
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return data.get("bundleVersion")
    except:
        pass
    return None

def calculate_marketing_version(year_str):
    """MarketingVersion = Year - 2018"""
    try:
        val = float(year_str)
        return round(val - 2018, 1)
    except:
        return None

def resolve_metadata_dir(base_path):
    """Resolves metadata and app paths."""
    if not base_path: return None, None
    base_path = os.path.expanduser(base_path.strip())
    if base_path.endswith(".app") or base_path.endswith(".app/"):
        app_path = base_path
        metadata_dir = os.path.join(base_path, "Contents/Resources/Metadata")
    elif "Contents/Resources/Metadata" in base_path:
        app_path = base_path.split("/Contents/Resources/Metadata")[0]
        metadata_dir = base_path
    else:
        if os.path.basename(base_path) == "Metadata":
            metadata_dir = base_path
            app_path = None
        else:
            metadata_dir = os.path.join(base_path, "Metadata")
            app_path = None
    if os.path.exists(metadata_dir): return metadata_dir, app_path
    return None, None

def main():
    parser = argparse.ArgumentParser(description="Extract SF Symbols metadata")
    parser.add_argument("--path", "-p", help="Path to 'SF Symbols.app' or 'Metadata'")
    parser.add_argument("--force", "-f", action="store_true", help="Force overwrite")
    args = parser.parse_args()

    initial_path = args.path or "/Applications/SF Symbols.app"
    metadata_dir, app_path = resolve_metadata_dir(initial_path)

    if not metadata_dir:
        print(f"Error: Metadata directory not found at: {initial_path}")
        sys.exit(1)

    current_app_version = get_app_version(app_path) if app_path else "0.0"
    output_dir = "Sources/UniversalSFSymbolsPicker/Resources"
    output_file = os.path.join(output_dir, "SFSymbolData.json")
    existing_version_str = get_existing_json_version(output_file)

    if existing_version_str and not args.force:
        if parse_version(current_app_version) < parse_version(existing_version_str):
            print(f"Aborting: Current app ({current_app_version}) is older than existing ({existing_version_str}).")
            sys.exit(1)

    print(f"Extracting SF Symbols metadata from: {metadata_dir} to JSON...")

    # 1. Load data
    availability_data = load_plist_or_strings(os.path.join(metadata_dir, "name_availability.plist"))
    if not availability_data: sys.exit(1)

    symbols_raw = availability_data.get("symbols", {})
    year_to_symbols = {}
    for symbol, year in symbols_raw.items():
        year_to_symbols.setdefault(year, []).append(symbol)

    year_to_release = availability_data.get("year_to_release", {})
    years = sorted(year_to_release.keys())
    latest_year = years[-1] if years else "unknown"
    version_to_year = {str(calculate_marketing_version(y)): y for y in years if calculate_marketing_version(y) is not None}

    aliases = {}
    for filename in ["name_aliases.strings", "legacy_aliases.strings"]:
        path = os.path.join(metadata_dir, filename)
        if os.path.exists(path):
            data = load_plist_or_strings(path)
            if data: aliases.update(data)

    symbol_categories = load_plist_or_strings(os.path.join(metadata_dir, "symbol_categories.plist")) or {}
    categories_raw = load_plist_or_strings(os.path.join(metadata_dir, "categories.plist")) or []
    excluded_category_keys = {"whatsnew", "draw", "variable", "multicolor"}
    
    categories = []
    for cat in categories_raw:
        if cat.get("key") not in excluded_category_keys:
            categories.append({
                "id": cat.get("key", ""),
                "label": cat.get("label", ""),
                "icon": cat.get("icon", "")
            })
    
    symbol_search = load_plist_or_strings(os.path.join(metadata_dir, "symbol_search.plist")) or {}
    restrictions_path = "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/symbol_restrictions.strings"
    restricted_symbols = load_plist_or_strings(restrictions_path) or {}

    # 2. Build final data structure
    data_out = {
        "bundleVersion": current_app_version,
        "latestYear": latest_year,
        "versionToYear": version_to_year,
        "yearToVersion": year_to_release,
        "categories": categories,
        "aliases": aliases,
        "symbolCategories": symbol_categories,
        "symbolAvailability": year_to_symbols,
        "searchKeywords": symbol_search,
        "restrictedSymbols": restricted_symbols
    }

    # 3. Write to JSON
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    print(f"Generating {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data_out, f, indent=2, ensure_ascii=False)

    print("Success: SF Symbols data has been saved to JSON correctly.")

if __name__ == "__main__":
    main()
