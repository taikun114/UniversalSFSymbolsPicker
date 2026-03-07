#!/usr/bin/env python3
import os
import plistlib
import re
import subprocess
import argparse
import sys

def load_plist_or_strings(path):
    """
    Loads a .plist or .strings file using plutil to convert it to XML first.
    Returns a dictionary or the parsed object.
    """
    try:
        # Use plutil to convert to XML and output to stdout
        result = subprocess.run(['plutil', '-convert', 'xml1', '-o', '-', path], 
                                capture_output=True, check=True)
        return plistlib.loads(result.stdout)
    except Exception as e:
        print(f"Warning: Failed to load {path}: {e}")
        return None

def get_app_version(app_path):
    """
    Reads the version of the SF Symbols app from its Info.plist.
    """
    info_plist_path = os.path.join(app_path, "Contents/Info.plist")
    if os.path.exists(info_plist_path):
        try:
            with open(info_plist_path, 'rb') as f:
                info = plistlib.load(f)
                return info.get("CFBundleShortVersionString", "unknown")
        except:
            pass
    return "unknown"

def calculate_marketing_version(year_str):
    """
    Calculates the SF Symbols marketing version from the metadata year string.
    Rule: MarketingVersion = Year - 2018
    """
    try:
        val = float(year_str)
        return round(val - 2018, 1)
    except:
        return None

def resolve_metadata_dir(base_path):
    """
    Resolves the metadata directory path from a base path (app or metadata dir).
    Returns (metadata_dir, app_path) or (None, None) if not found.
    """
    if not base_path:
        return None, None
    
    base_path = os.path.expanduser(base_path.strip())
    
    if base_path.endswith(".app") or base_path.endswith(".app/"):
        app_path = base_path
        metadata_dir = os.path.join(base_path, "Contents/Resources/Metadata")
    elif "Contents/Resources/Metadata" in base_path:
        app_path = base_path.split("/Contents/Resources/Metadata")[0]
        metadata_dir = base_path
    else:
        # Check if Metadata folder exists directly or inside the path
        if os.path.basename(base_path) == "Metadata":
            metadata_dir = base_path
            app_path = None
        else:
            metadata_dir = os.path.join(base_path, "Metadata")
            app_path = None

    if os.path.exists(metadata_dir):
        return metadata_dir, app_path
    return None, None

def main():
    parser = argparse.ArgumentParser(description="Extract SF Symbols metadata for UniversalSFSymbolsPicker")
    parser.add_argument(
        "--path", "-p",
        help="Path to 'SF Symbols.app' or the 'Metadata' directory inside it."
    )
    args = parser.parse_args()

    # Try default paths or provided path
    initial_path = args.path or "/Applications/SF Symbols.app"
    metadata_dir, app_path = resolve_metadata_dir(initial_path)

    # Interactive input loop if not found
    current_attempt_path = initial_path
    while not metadata_dir:
        print(f"\nError: SF Symbols Metadata directory not found at: {current_attempt_path}")
        print("Please provide the correct path to 'SF Symbols.app' or the 'Metadata' folder.")
        print("(Press Enter to exit)")
        
        user_input = input("Path: ").strip()
        if not user_input:
            print("Exiting...")
            sys.exit(1)
            
        current_attempt_path = user_input
        metadata_dir, app_path = resolve_metadata_dir(user_input)

    # Get marketing version (e.g., 6.1)
    app_version = get_app_version(app_path) if app_path else "unknown"

    print(f"\nExtracting SF Symbols metadata (App Version: {app_version}) from: {metadata_dir}")

    # 1. Load data
    availability_path = os.path.join(metadata_dir, "name_availability.plist")
    availability_data = load_plist_or_strings(availability_path)
    if not availability_data:
        print(f"Error: Could not load availability data from {availability_path}")
        sys.exit(1)

    symbols_raw = availability_data.get("symbols", {})
    year_to_symbols = {}
    for symbol, year in symbols_raw.items():
        year_to_symbols.setdefault(year, []).append(symbol)

    year_to_release = availability_data.get("year_to_release", {})
    years = sorted(year_to_release.keys())
    latest_year = years[-1] if years else "unknown"

    version_to_year = {calculate_marketing_version(y): y for y in years if calculate_marketing_version(y) is not None}

    aliases = {}
    for filename in ["name_aliases.strings", "legacy_aliases.strings"]:
        path = os.path.join(metadata_dir, filename)
        if os.path.exists(path):
            data = load_plist_or_strings(path)
            if data:
                aliases.update(data)

    symbol_categories = load_plist_or_strings(os.path.join(metadata_dir, "symbol_categories.plist")) or {}
    categories_raw = load_plist_or_strings(os.path.join(metadata_dir, "categories.plist")) or []
    symbol_search = load_plist_or_strings(os.path.join(metadata_dir, "symbol_search.plist")) or {}

    # 2. Generate Swift Code
    output_dir = "Sources/UniversalSFSymbolsPicker"
    output_file = os.path.join(output_dir, "SFSymbolData.swift")
    if not os.path.exists(output_dir): os.makedirs(output_dir)

    print(f"Generating {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("// Generated by Utilities/extract_metadata.py\n")
        f.write("// DO NOT EDIT MANUALLY\n\n")
        f.write("import Foundation\n\n")
        f.write("enum SFSymbolData {\n")
        f.write(f'    /// The marketing version of the SF Symbols app used for extraction\n')
        f.write(f'    static let bundleVersion: String = "{app_version}"\n\n')
        f.write(f'    /// The latest introduction year available in this metadata\n')
        f.write(f'    static let latestYear: String = "{latest_year}"\n\n')

        f.write("    /// Map of SF Symbols marketing version to metadata year string\n")
        f.write("    static let versionToYear: [Double: String] = [\n")
        for v in sorted(version_to_year.keys()):
            f.write(f'        {v}: "{version_to_year[v]}",\n')
        f.write("    ]\n\n")

        f.write("    /// Map of year string to OS versions\n")
        f.write("    static let yearToVersion: [String: [String: String]] = [\n")
        for year, versions in sorted(year_to_release.items()):
            f.write(f'        "{year}": [\n')
            for os_name, version in sorted(versions.items()):
                f.write(f'            "{os_name}": "{version}",\n')
            f.write("        ],\n")
        f.write("    ]\n\n")

        f.write("    /// List of available categories\n")
        f.write("    static let categories: [[String: String]] = [\n")
        for cat in categories_raw:
            f.write('        [\n')
            f.write(f'            "id": "{cat.get("key", "")}",\n')
            f.write(f'            "label": "{cat.get("label", "")}",\n')
            f.write(f'            "icon": "{cat.get("icon", "")}"\n')
            f.write('        ],\n')
        f.write("    ]\n\n")

        f.write("    /// Map of old symbol names to new names (aliases)\n")
        f.write("    static let aliases: [String: String] = [\n")
        for old_name, new_name in sorted(aliases.items()):
            f.write(f'        "{old_name}": "{new_name}",\n')
        f.write("    ]\n\n")

        f.write("    /// Map of symbol name to its categories\n")
        f.write("    static let symbolCategories: [String: [String]] = [\n")
        for symbol, cats in sorted(symbol_categories.items()):
            f.write(f'        "{symbol}": [\n')
            for cat in sorted(cats):
                f.write(f'            "{cat}",\n')
            f.write("        ],\n")
        f.write("    ]\n\n")

        f.write("    /// Map of year string to the list of symbols introduced in that year\n")
        f.write("    static let symbolAvailability: [String: [String]] = [\n")
        for year in sorted(year_to_symbols.keys()):
            symbols = sorted(year_to_symbols[year])
            f.write(f'        "{year}": [\n')
            for symbol in symbols:
                f.write(f'            "{symbol}",\n')
            f.write("        ],\n")
        f.write("    ]\n\n")

        f.write("    /// Map of symbol name to search keywords\n")
        f.write("    static let searchKeywords: [String: [String]] = [\n")
        for symbol, keywords in sorted(symbol_search.items()):
            f.write(f'        "{symbol}": [\n')
            for keyword in sorted(keywords):
                safe_keyword = keyword.replace('"', '\\"')
                f.write(f'            "{safe_keyword}",\n')
            f.write("        ],\n")
        f.write("    ]\n")
        f.write("}\n")

    print("Success: SF Symbols data has been extracted and saved to Swift.")

if __name__ == "__main__":
    main()
