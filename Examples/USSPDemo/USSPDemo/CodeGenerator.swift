import Foundation
import SwiftUI
import UniversalSFSymbolsPicker

struct BuildModeOptions {
    // Core Options
    var enableDisplayMode: Bool = false
    var displayMode: SFSymbolPickerDisplayMode = .sheet
    
    var enableControlBarPosition: Bool = false
    var controlBarPosition: SFSymbolPickerControlBarPosition = .bottom
    
    // Search Bar
    var enableShowSearchBar: Bool = false
    var showSearchBar: Bool = true
    
    var useSearchable: Bool = false
    
    // Categories & UI
    var enableShowCategoryPicker: Bool = false
    var showCategoryPicker: Bool = true
    
    var enableShowCategorySectionLabel: Bool = false
    var showCategorySectionLabel: Bool = true
    
    var enableCategoryLabelVisibility: Bool = false
    var categoryLabelVisibility: SFSymbolPickerCategoryLabelVisibility = .default
    
    var enableCategoryLabelStyle: Bool = false
    var categoryLabelStyle: SFSymbolPickerCategoryLabelStyle = .both
    
    var enableShowIconName: Bool = false
    var showIconName: Bool = true
    
    var enableExcludeRestricted: Bool = false
    var excludeRestricted: Bool = false
    
    var enableIconScale: Bool = false
    var iconScale: Int = 5
    
    var enableShowRecents: Bool = false
    var showRecents: Bool = false
    
    var enableMaxRecents: Bool = false
    var maxRecents: Int = 20
    
    // Styling
    var enableRenderingMode: Bool = false
    var renderingModeOption: RenderingModeOption = .monochrome
    
    var enableIsGradient: Bool = false
    var isGradient: Bool = false
    
    var enablePrimaryColor: Bool = false
    var enableSecondaryColor: Bool = false
    var enableTertiaryColor: Bool = false
    
    var enableVariableValue: Bool = false
}

struct CodeGenerator {
    static func generate(options: BuildModeOptions) -> String {
        var args: [String] = []
        args.append("isPresented: $isPresented")
        args.append("selection: $selectedIcon")
        
        // Core options overrides
        if options.enableDisplayMode {
            args.append("showAs: .\(String(describing: options.displayMode))")
        }
        if options.enableControlBarPosition {
            args.append("controlBarPosition: .\(String(describing: options.controlBarPosition))")
        }
        
        // Search Bar logic
        let isUseSearchableActive = options.useSearchable
        
        if isUseSearchableActive {
            args.append("showSearchBar: false")
        } else if options.enableShowSearchBar {
            args.append("showSearchBar: \(options.showSearchBar)")
        }
        
        // Boolean overrides
        if options.enableShowCategoryPicker {
            args.append("showCategoryPicker: \(options.showCategoryPicker)")
        }
        if options.enableShowCategorySectionLabel {
            args.append("showCategorySectionLabel: \(options.showCategorySectionLabel)")
        }
        if options.enableShowIconName {
            args.append("showIconName: \(options.showIconName)")
        }
        if options.enableExcludeRestricted {
            args.append("excludeRestricted: \(options.excludeRestricted)")
        }
        if options.enableShowRecents {
            args.append("showRecents: \(options.showRecents)")
        }
        if options.enableIsGradient {
            args.append("isGradient: \(options.isGradient)")
        }
        
        // Other overrides
        if options.enableCategoryLabelVisibility {
            args.append("categoryLabelVisibility: .\(String(describing: options.categoryLabelVisibility))")
        }
        if options.enableCategoryLabelStyle {
            args.append("categoryLabelStyle: .\(String(describing: options.categoryLabelStyle))")
        }
        if options.enableIconScale {
            args.append("iconScale: \(options.iconScale)")
        }
        if options.enableMaxRecents {
            args.append("maxRecents: \(options.maxRecents)")
        }
        if options.enableRenderingMode {
            args.append("renderingMode: .\(options.renderingModeOption.rawValue)")
        }
        
        // Colors formatting
        if options.enablePrimaryColor {
            args.append("primaryColor: .blue /* Your color here */")
        }
        if options.enableSecondaryColor {
            args.append("secondaryColor: .red /* Your color here */")
        }
        if options.enableTertiaryColor {
            args.append("tertiaryColor: .green /* Your color here */")
        }
        
        if options.enableVariableValue {
            args.append("variableValue: $myValue")
        }
        
        // Search text binding
        let isCustomSearchBarVisible = isUseSearchableActive ? false : (!options.enableShowSearchBar || options.showSearchBar)
        if isCustomSearchBarVisible {
            args.append("searchText: $searchText")
        }
        
        let argsString = args.joined(separator: ",\n    ")
        var pickerCode = ""
        
        if isUseSearchableActive {
            pickerCode += "NavigationStack {\n"
            pickerCode += "    SFSymbolPicker(\n        \(argsString.replacingOccurrences(of: "\n", with: "\n        "))\n    )\n"
            pickerCode += "    .searchable(text: $searchText)\n"
            pickerCode += "}"
        } else {
            pickerCode += "SFSymbolPicker(\n    \(argsString.replacingOccurrences(of: "\n", with: "\n    "))\n)"
        }
        
        let modifierName = (options.enableDisplayMode && options.displayMode == .popover) ? "popover" : "sheet"
        
        var code = ""
        if options.enableVariableValue {
            code += "@State private var myValue: Double? = 0.7\n\n"
        }
        
        code += "Button(\"Show Icon Picker\") {\n"
        code += "    isPresented = true\n"
        code += "}\n"
        code += ".\(modifierName)(isPresented: $isPresented) {\n"
        code += "    \(pickerCode.replacingOccurrences(of: "\n", with: "\n    "))\n"
        code += "}"
        
        return code
    }
}
