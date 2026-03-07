import Foundation

/// Represents a user-defined category for SF Symbols.
/// It can contain an explicit list of symbol names and/or include entire system categories.
public struct CustomCategory: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let label: String
    public let icon: String
    
    /// Explicit list of symbol names included in this category.
    public let symbols: [String]
    
    /// List of system category IDs (e.g., "devices", "gaming") to be included in this category.
    public let systemCategories: [String]
    
    public init(
        id: UUID = UUID(),
        label: String,
        icon: String,
        symbols: [String] = [],
        systemCategories: [String] = []
    ) {
        self.id = id
        self.label = label
        self.icon = icon
        self.symbols = symbols
        self.systemCategories = systemCategories
    }
}
