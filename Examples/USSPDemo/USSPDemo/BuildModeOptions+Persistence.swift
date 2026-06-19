import Foundation
import SwiftUI
import UniversalSFSymbolsPicker

extension BuildModeOptions: Codable, RawRepresentable {
    enum CodingKeys: String, CodingKey {
        case enableDisplayMode, displayMode, enableControlBarPosition, controlBarPosition
        case enableShowSearchBar, showSearchBar, useSearchable
        case enableShowCategoryPicker, showCategoryPicker
        case enableShowCategorySectionLabel, showCategorySectionLabel
        case enableCategoryLabelVisibility, categoryLabelVisibility
        case enableCategoryLabelStyle, categoryLabelStyle
        case enableShowIconName, showIconName
        case enableExcludeRestricted, excludeRestricted
        case enableIconScale, iconScale
        case enableIconSpacing, iconSpacing
        case enableShowRecents, showRecents
        case enableMaxRecents, maxRecents
        case enableRenderingMode, renderingModeOption
        case enableIsGradient, isGradient
        case enablePrimaryColor, enableSecondaryColor, enableTertiaryColor
        case enableVariableValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        self.enableDisplayMode = try container.decode(Bool.self, forKey: .enableDisplayMode)
        let displayModeStr = try container.decode(String.self, forKey: .displayMode)
        self.displayMode = displayModeStr == "popover" ? .popover : .sheet
        
        self.enableControlBarPosition = try container.decode(Bool.self, forKey: .enableControlBarPosition)
        let controlBarPositionStr = try container.decode(String.self, forKey: .controlBarPosition)
        self.controlBarPosition = controlBarPositionStr == "top" ? .top : .bottom
        
        self.enableShowSearchBar = try container.decode(Bool.self, forKey: .enableShowSearchBar)
        self.showSearchBar = try container.decode(Bool.self, forKey: .showSearchBar)
        self.useSearchable = try container.decode(Bool.self, forKey: .useSearchable)
        
        self.enableShowCategoryPicker = try container.decode(Bool.self, forKey: .enableShowCategoryPicker)
        self.showCategoryPicker = try container.decode(Bool.self, forKey: .showCategoryPicker)
        
        self.enableShowCategorySectionLabel = try container.decode(Bool.self, forKey: .enableShowCategorySectionLabel)
        self.showCategorySectionLabel = try container.decode(Bool.self, forKey: .showCategorySectionLabel)
        
        self.enableCategoryLabelVisibility = try container.decode(Bool.self, forKey: .enableCategoryLabelVisibility)
        let categoryLabelVisibilityStr = try container.decode(String.self, forKey: .categoryLabelVisibility)
        switch categoryLabelVisibilityStr {
        case "visible": self.categoryLabelVisibility = .visible
        case "hidden": self.categoryLabelVisibility = .hidden
        default: self.categoryLabelVisibility = .default
        }
        
        self.enableCategoryLabelStyle = try container.decode(Bool.self, forKey: .enableCategoryLabelStyle)
        let categoryLabelStyleStr = try container.decode(String.self, forKey: .categoryLabelStyle)
        switch categoryLabelStyleStr {
        case "titleOnly": self.categoryLabelStyle = .titleOnly
        case "nameOnly": self.categoryLabelStyle = .nameOnly
        default: self.categoryLabelStyle = .both
        }
        
        self.enableShowIconName = try container.decode(Bool.self, forKey: .enableShowIconName)
        self.showIconName = try container.decode(Bool.self, forKey: .showIconName)
        
        self.enableExcludeRestricted = try container.decode(Bool.self, forKey: .enableExcludeRestricted)
        self.excludeRestricted = try container.decode(Bool.self, forKey: .excludeRestricted)
        
        self.enableIconScale = try container.decode(Bool.self, forKey: .enableIconScale)
        self.iconScale = try container.decode(Int.self, forKey: .iconScale)
        
        self.enableIconSpacing = try container.decodeIfPresent(Bool.self, forKey: .enableIconSpacing) ?? false
        self.iconSpacing = try container.decodeIfPresent(Int.self, forKey: .iconSpacing) ?? 5
        
        self.enableShowRecents = try container.decode(Bool.self, forKey: .enableShowRecents)
        self.showRecents = try container.decode(Bool.self, forKey: .showRecents)
        
        self.enableMaxRecents = try container.decode(Bool.self, forKey: .enableMaxRecents)
        self.maxRecents = try container.decode(Int.self, forKey: .maxRecents)
        
        self.enableRenderingMode = try container.decode(Bool.self, forKey: .enableRenderingMode)
        let renderingModeOptionStr = try container.decode(String.self, forKey: .renderingModeOption)
        self.renderingModeOption = RenderingModeOption(rawValue: renderingModeOptionStr) ?? .monochrome
        
        self.enableIsGradient = try container.decode(Bool.self, forKey: .enableIsGradient)
        self.isGradient = try container.decode(Bool.self, forKey: .isGradient)
        
        self.enablePrimaryColor = try container.decode(Bool.self, forKey: .enablePrimaryColor)
        self.enableSecondaryColor = try container.decode(Bool.self, forKey: .enableSecondaryColor)
        self.enableTertiaryColor = try container.decode(Bool.self, forKey: .enableTertiaryColor)
        self.enableVariableValue = try container.decode(Bool.self, forKey: .enableVariableValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enableDisplayMode, forKey: .enableDisplayMode)
        try container.encode(displayMode == .popover ? "popover" : "sheet", forKey: .displayMode)
        
        try container.encode(enableControlBarPosition, forKey: .enableControlBarPosition)
        try container.encode(controlBarPosition == .top ? "top" : "bottom", forKey: .controlBarPosition)
        
        try container.encode(enableShowSearchBar, forKey: .enableShowSearchBar)
        try container.encode(showSearchBar, forKey: .showSearchBar)
        try container.encode(useSearchable, forKey: .useSearchable)
        
        try container.encode(enableShowCategoryPicker, forKey: .enableShowCategoryPicker)
        try container.encode(showCategoryPicker, forKey: .showCategoryPicker)
        
        try container.encode(enableShowCategorySectionLabel, forKey: .enableShowCategorySectionLabel)
        try container.encode(showCategorySectionLabel, forKey: .showCategorySectionLabel)
        
        try container.encode(enableCategoryLabelVisibility, forKey: .enableCategoryLabelVisibility)
        let categoryLabelVisibilityStr: String
        switch categoryLabelVisibility {
        case .visible: categoryLabelVisibilityStr = "visible"
        case .hidden: categoryLabelVisibilityStr = "hidden"
        default: categoryLabelVisibilityStr = "default"
        }
        try container.encode(categoryLabelVisibilityStr, forKey: .categoryLabelVisibility)
        
        try container.encode(enableCategoryLabelStyle, forKey: .enableCategoryLabelStyle)
        let categoryLabelStyleStr: String
        switch categoryLabelStyle {
        case .titleOnly: categoryLabelStyleStr = "titleOnly"
        case .nameOnly: categoryLabelStyleStr = "nameOnly"
        default: categoryLabelStyleStr = "both"
        }
        try container.encode(categoryLabelStyleStr, forKey: .categoryLabelStyle)
        
        try container.encode(enableShowIconName, forKey: .enableShowIconName)
        try container.encode(showIconName, forKey: .showIconName)
        
        try container.encode(enableExcludeRestricted, forKey: .enableExcludeRestricted)
        try container.encode(excludeRestricted, forKey: .excludeRestricted)
        
        try container.encode(enableIconScale, forKey: .enableIconScale)
        try container.encode(iconScale, forKey: .iconScale)
        
        try container.encode(enableIconSpacing, forKey: .enableIconSpacing)
        try container.encode(iconSpacing, forKey: .iconSpacing)
        
        try container.encode(enableShowRecents, forKey: .enableShowRecents)
        try container.encode(showRecents, forKey: .showRecents)
        
        try container.encode(enableMaxRecents, forKey: .enableMaxRecents)
        try container.encode(maxRecents, forKey: .maxRecents)
        
        try container.encode(enableRenderingMode, forKey: .enableRenderingMode)
        try container.encode(renderingModeOption.rawValue, forKey: .renderingModeOption)
        
        try container.encode(enableIsGradient, forKey: .enableIsGradient)
        try container.encode(isGradient, forKey: .isGradient)
        
        try container.encode(enablePrimaryColor, forKey: .enablePrimaryColor)
        try container.encode(enableSecondaryColor, forKey: .enableSecondaryColor)
        try container.encode(enableTertiaryColor, forKey: .enableTertiaryColor)
        try container.encode(enableVariableValue, forKey: .enableVariableValue)
    }
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(BuildModeOptions.self, from: data) else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return result
    }
}
