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
    
    var enableIconSpacing: Bool = false
    var iconSpacing: Int = 5
    
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
        // Core options overrides
        args.append("isPresented: $isPresented")
        args.append("selection: $selectedIcon")
        
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
        
        // Search text binding
        let isCustomSearchBarVisible = isUseSearchableActive ? false : (!options.enableShowSearchBar || options.showSearchBar)
        let needsSearchText = isCustomSearchBarVisible || isUseSearchableActive
        if needsSearchText {
            args.append("searchText: $searchText")
        }
        
        // Categories & UI
        if options.enableShowCategoryPicker {
            args.append("showCategoryPicker: \(options.showCategoryPicker)")
        }
        if options.enableShowCategorySectionLabel {
            args.append("showCategorySectionLabel: \(options.showCategorySectionLabel)")
        }
        if options.enableCategoryLabelVisibility {
            args.append("categoryLabelVisibility: .\(String(describing: options.categoryLabelVisibility))")
        }
        if options.enableCategoryLabelStyle {
            args.append("categoryLabelStyle: .\(String(describing: options.categoryLabelStyle))")
        }
        if options.enableShowIconName {
            args.append("showIconName: \(options.showIconName)")
        }
        if options.enableExcludeRestricted {
            args.append("excludeRestricted: \(options.excludeRestricted)")
        }
        if options.enableIconScale {
            args.append("iconScale: \(options.iconScale)")
        }
        if options.enableIconSpacing {
            args.append("iconSpacing: \(options.iconSpacing)")
        }
        if options.enableShowRecents {
            args.append("showRecents: \(options.showRecents)")
        }
        if options.enableMaxRecents {
            args.append("maxRecents: \(options.maxRecents)")
        }
        
        // Styling
        if options.enableRenderingMode {
            args.append("renderingMode: .\(options.renderingModeOption.rawValue)")
        }
        if options.enableIsGradient {
            args.append("isGradient: \(options.isGradient)")
        }
        
        // Colors formatting
        let colorComment = String(localized: "Your color here")
        if options.enablePrimaryColor {
            args.append("primaryColor: .blue /* \(colorComment) */")
        }
        if options.enableSecondaryColor {
            args.append("secondaryColor: .red /* \(colorComment) */")
        }
        if options.enableTertiaryColor {
            args.append("tertiaryColor: .green /* \(colorComment) */")
        }
        
        if options.enableVariableValue {
            let bindComment = String(localized: "Bind your value here")
            args.append("variableValue: $myValue /* \(bindComment) */")
        }
        
        let modifierName = (options.enableDisplayMode && options.displayMode == .popover) ? "popover" : "sheet"
        let needsNavigationStack = isUseSearchableActive || modifierName == "sheet"
        
        let argsString = args.joined(separator: ",\n")
        var pickerCode = ""
        
        if needsNavigationStack {
            pickerCode += "NavigationStack {\n"
            pickerCode += "    SFSymbolPicker(\n        \(argsString.replacingOccurrences(of: "\n", with: "\n        "))\n    )\n"
            if isUseSearchableActive {
                pickerCode += "    .searchable(text: $searchText)\n"
            }
            pickerCode += "}"
        } else {
            pickerCode += "SFSymbolPicker(\n    \(argsString.replacingOccurrences(of: "\n", with: "\n    "))\n)"
        }
        
        var code = ""
        code += "@State private var isPresented = false\n"
        code += "@State private var selectedIcon: String? = \"star.fill\"\n"
        if needsSearchText {
            code += "@State private var searchText = \"\"\n"
        }
        if options.enableVariableValue {
            code += "@State private var myValue: Double? = 0.7\n"
        }
        code += "\n"
        
        code += "Button(\"Show Icon Picker\") {\n"
        code += "    isPresented = true\n"
        code += "}\n"
        code += ".\(modifierName)(isPresented: $isPresented) {\n"
        code += "    \(pickerCode.replacingOccurrences(of: "\n", with: "\n    "))\n"
        code += "}"
        
        return code
    }
}
