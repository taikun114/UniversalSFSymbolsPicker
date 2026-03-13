
import json
import subprocess
import os
import sys

# Special overrides for mapping Package language codes (BCP 47) to SF Symbols app resource folders.
# Apple uses zh_CN.lproj for Simplified Chinese (zh-Hans) and zh_TW.lproj for Traditional (zh-Hant).
LANG_MAP_OVERRIDES = {
    "zh-Hans": "zh_CN",
    "zh-Hant": "zh_TW",
    "zh-HK": "zh_HK",
    "fr-CA": "fr_CA",
    "pt-BR": "pt_BR",
}

# Mapping from SF Symbols property keys to our Localizable keys.
# This tool is specialized for validating System Category names.
KEY_MAP = {
    "sfsymbols-category-accessibility": "Accessibility",
    "sfsymbols-category-all": "All",
    "sfsymbols-category-arrows": "Arrows",
    "sfsymbols-category-automotive": "Automotive",
    "sfsymbols-category-cameraandphotos": "Camera & Photos",
    "sfsymbols-category-commerce": "Commerce",
    "sfsymbols-category-communication": "Communication",
    "sfsymbols-category-connectivity": "Connectivity",
    "sfsymbols-category-devices": "Devices",
    "sfsymbols-category-editing": "Editing",
    "sfsymbols-category-fitness": "Fitness",
    "sfsymbols-category-gaming": "Gaming",
    "sfsymbols-category-health": "Health",
    "sfsymbols-category-home": "Home",
    "sfsymbols-category-human": "Human",
    "sfsymbols-category-indices": "Indices",
    "sfsymbols-category-keyboard": "Keyboard",
    "sfsymbols-category-maps": "Maps",
    "sfsymbols-category-math": "Math",
    "sfsymbols-category-media": "Media",
    "sfsymbols-category-nature": "Nature",
    "sfsymbols-category-objectsandtools": "Objects & Tools",
    "sfsymbols-category-privacyandsecurity": "Privacy & Security",
    "sfsymbols-category-shapes": "Shapes",
    "sfsymbols-category-textformatting": "Text Formatting",
    "sfsymbols-category-time": "Time",
    "sfsymbols-category-transportation": "Transportation",
    "sfsymbols-category-weather": "Weather"
}

XCSTRINGS_PATH = 'Sources/UniversalSFSymbolsPicker/Resources/Localizable.xcstrings'
DEFAULT_SF_SYMBOLS_PATH = '/Applications/SF Symbols.app/Contents/Frameworks/SFSymbolsShared.framework/Versions/A/Resources'

def get_sf_lang_code(pkg_lang):
    """Converts package language code to SF Symbols resource folder name."""
    return LANG_MAP_OVERRIDES.get(pkg_lang, pkg_lang.replace('-', '_'))

def get_official_translations(sf_lang, sf_symbols_path):
    """Extracts official category titles from SF Symbols app using plutil."""
    path = os.path.join(sf_symbols_path, f"{sf_lang}.lproj/CategoryTitles.strings")
    if not os.path.exists(path):
        return None
    
    try:
        result = subprocess.run(['plutil', '-convert', 'json', '-o', '-', path], capture_output=True, text=True)
        if result.returncode != 0:
            return None
        data = json.loads(result.stdout)
        # Strip values to remove potential trailing whitespace
        return {k: v.strip() for k, v in data.items()}
    except Exception:
        return None

def get_supported_languages(data):
    """Extracts all language codes currently present in Localizable.xcstrings."""
    langs = set()
    for string_key in data.get('strings', {}).values():
        if 'localizations' in string_key:
            for lang in string_key['localizations'].keys():
                langs.add(lang)
    return langs

def show_original_values(pkg_langs, sf_symbols_path):
    """Fetches and displays original SF Symbols category names without validation."""
    for pkg_lang in pkg_langs:
        sf_lang = get_sf_lang_code(pkg_lang)
        official = get_official_translations(sf_lang, sf_symbols_path)
        print(f"\n--- Official System Category Names for '{pkg_lang}' (Resource: {sf_lang}.lproj) ---")
        if not official:
            print(f"Error: Official data not found at {sf_symbols_path}/{sf_lang}.lproj")
            continue
        
        for sf_key, pkg_key in KEY_MAP.items():
            val = official.get(sf_key, "(Not found in official data)")
            print(f"  {pkg_key}: {val}")

def main():
    args = sys.argv[1:]
    langs_to_check = []
    langs_to_show_original = []
    sf_symbols_path = DEFAULT_SF_SYMBOLS_PATH
    
    # Argument Parsing
    show_orig_mode = False
    idx = 0
    while idx < len(args):
        arg = args[idx]
        if arg in ('-p', '--path'):
            if idx + 1 < len(args):
                sf_symbols_path = args[idx+1]
                idx += 2
                continue
            else:
                print("Error: --path requires an argument.")
                sys.exit(1)
        elif arg in ('-o', '--original'):
            show_orig_mode = True
            idx += 1
            continue
        
        if show_orig_mode:
            langs_to_show_original.append(arg)
        else:
            langs_to_check.append(arg)
        idx += 1

    # Resolve SF Symbols Path (Translation resources are in the Framework's Resources folder)
    if sf_symbols_path.endswith('.app') or sf_symbols_path.endswith('.app/'):
        potential_path = os.path.join(sf_symbols_path, 'Contents/Frameworks/SFSymbolsShared.framework/Versions/A/Resources')
        if os.path.exists(potential_path):
            sf_symbols_path = potential_path
        else:
            print(f"Warning: Could not find Resources in provided app bundle: {sf_symbols_path}")

    # 1. Load Package Data
    if not os.path.exists(XCSTRINGS_PATH):
        print(f"Error: {XCSTRINGS_PATH} not found.")
        sys.exit(1)

    with open(XCSTRINGS_PATH, 'r') as f:
        data = json.load(f)

    supported_langs = get_supported_languages(data)

    # 2. Validation Mode
    if langs_to_check or (not langs_to_show_original and not args):
        if not langs_to_check:
            langs_to_check = sorted(list(supported_langs))

        print(f"Checking system category translations for: {', '.join(langs_to_check)}")
        print(f"Using SF Symbols Resources: {sf_symbols_path}")
        all_diffs = []
        
        for pkg_lang in langs_to_check:
            if pkg_lang not in supported_langs:
                print(f"  Error: Language '{pkg_lang}' is not present in Localizable.xcstrings. Please add it first or use -o to see original values.")
                all_diffs.append(f"Not supported: {pkg_lang}")
                continue
                
            sf_lang = get_sf_lang_code(pkg_lang)
            official = get_official_translations(sf_lang, sf_symbols_path)
            if not official:
                print(f"  Skipping {pkg_lang}: Official data not found for resource folder '{sf_lang}.lproj'.")
                continue

            lang_diffs = []
            for sf_key, pkg_key in KEY_MAP.items():
                if sf_key not in official: continue
                official_val = official[sf_key]
                
                if pkg_key not in data['strings']:
                    lang_diffs.append(f"    Key missing in xcstrings: {pkg_key}")
                    continue
                
                localizations = data['strings'][pkg_key].get('localizations', {})
                if pkg_lang not in localizations:
                    lang_diffs.append(f"    Translation missing for {pkg_lang}: {pkg_key}")
                    continue
                
                pkg_val = localizations[pkg_lang]['stringUnit']['value'].strip()
                if pkg_val != official_val:
                    lang_diffs.append(f"    Mismatch in {pkg_key}: Package='{pkg_val}', Official='{official_val}'")

            if lang_diffs:
                print(f"  Differences found for {pkg_lang}:")
                for diff in lang_diffs: print(diff)
                all_diffs.extend(lang_diffs)
            else:
                print(f"  ✓ {pkg_lang}: Match")
        
        if not all_diffs:
            print("\nValidation complete: All checked categories match official SF Symbols data.")
        else:
            print(f"\nValidation finished with errors/mismatches.")

    # 3. Show Original Mode
    if langs_to_show_original:
        show_original_values(langs_to_show_original, sf_symbols_path)

if __name__ == "__main__":
    main()
