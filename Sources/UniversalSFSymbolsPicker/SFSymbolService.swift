import Foundation
import SwiftUI

/// Represents a category of SF Symbols.
public struct SFSymbolCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let icon: String
}

/// A service that provides access to SF Symbols metadata, availability, categories, and search keywords.
public final class SFSymbolService: Sendable {
    public static let shared = SFSymbolService()
    
    /// All unique symbol identifiers (canonical names).
    public let allSymbols: [String]
    
    /// All available system categories.
    public let systemCategories: [SFSymbolCategory]
    
    /// Internal map: Symbol Name -> Introduction Year
    private let symbolToYear: [String: String]
    
    /// Internal map: Symbol Name -> List of Categories
    private let symbolToCategories: [String: [String]]
    
    /// Internal map: Symbol Name -> List of Keywords
    private let symbolToKeywords: [String: [String]]
    
    /// Internal map: Symbol Name -> Restriction Reason
    private let restrictedSymbols: [String: String]
    
    /// Internal map: Old Name -> New Name
    private let aliases: [String: String]
    
    /// Internal map: New Name -> [Old Names]
    private let reverseAliases: [String: [String]]
    
    private init() {
        var allNames = [String]()
        var lookupYear = [String: String]()
        
        for (year, symbols) in SFSymbolData.symbolAvailability {
            allNames.append(contentsOf: symbols)
            for symbol in symbols {
                lookupYear[symbol] = year
            }
        }
        
        self.symbolToYear = lookupYear
        self.aliases = SFSymbolData.aliases
        self.restrictedSymbols = SFSymbolData.restrictedSymbols
        
        // Build reverse aliases for fallback lookup
        var rev = [String: [String]]()
        for (old, new) in SFSymbolData.aliases {
            rev[new, default: []].append(old)
        }
        self.reverseAliases = rev
        
        // Canonical symbols are those that are NOT an old alias for something else
        let oldAliasSet = Set(SFSymbolData.aliases.keys)
        self.allSymbols = allNames.filter { !oldAliasSet.contains($0) }.sorted()
        
        self.systemCategories = SFSymbolData.categories.map { dict in
            SFSymbolCategory(
                id: dict["id"] ?? "",
                label: dict["label"] ?? "",
                icon: dict["icon"] ?? ""
            )
        }
        
        self.symbolToCategories = SFSymbolData.symbolCategories
        self.symbolToKeywords = SFSymbolData.searchKeywords
    }
    
    // MARK: - Dynamic Naming
    
    public func effectiveName(for name: String) -> String? {
        let cluster = findSymbolCluster(startingWith: name)
        let sortedNames = cluster.sorted { a, b in
            let yearA = symbolToYear[a] ?? "0"
            let yearB = symbolToYear[b] ?? "0"
            return yearA.compare(yearB, options: .numeric) == .orderedDescending
        }
        return sortedNames.first { isAvailable($0) }
    }
    
    private func findSymbolCluster(startingWith name: String) -> Set<String> {
        var cluster = Set<String>([name])
        var queue = [name]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let new = aliases[current], !cluster.contains(new) {
                cluster.insert(new)
                queue.append(new)
            }
            if let olds = reverseAliases[current] {
                for old in olds where !cluster.contains(old) {
                    cluster.insert(old)
                    queue.append(old)
                }
            }
        }
        return cluster
    }
    
    // MARK: - Availability
    
    public func isAvailable(_ symbol: String, limitVersion: Double? = nil) -> Bool {
        guard let year = symbolToYear[symbol] else { return false }
        if let limit = limitVersion, let limitYear = SFSymbolData.versionToYear[limit] {
            if year.compare(limitYear, options: .numeric) == .orderedDescending { return false }
        }
        guard let versions = SFSymbolData.yearToVersion[year] else { return false }
        
        var currentOS: String? = nil
        #if os(iOS)
        currentOS = "iOS"
        #elseif os(macOS)
        currentOS = "macOS"
        #elseif os(tvOS)
        currentOS = "tvOS"
        #elseif os(watchOS)
        currentOS = "watchOS"
        #elseif os(visionOS)
        currentOS = "visionOS"
        #endif
        
        guard let osKey = currentOS, let requiredVersionString = versions[osKey] else { return false }
        let requiredVersion = OperatingSystemVersion(versionString: requiredVersionString)
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(requiredVersion)
    }
    
    // MARK: - Filtering & Search
    
    public func symbols(
        for categoryID: String,
        customCategories: [CustomCategory] = [],
        includedIDs: [String]? = nil,
        excludedIDs: [String]? = nil,
        excludeRestricted: Bool = false,
        limitVersion: Double? = nil
    ) -> [String] {
        var baseSymbols: Set<String>
        
        if categoryID == "all" {
            baseSymbols = Set(allSymbols)
        } else if let custom = customCategories.first(where: { $0.id.uuidString == categoryID }) {
            baseSymbols = Set(custom.symbols)
            for sysID in custom.systemCategories {
                baseSymbols.formUnion(symbolsInSystemCategory(sysID))
            }
        } else {
            baseSymbols = symbolsInSystemCategory(categoryID)
        }
        
        if let included = includedIDs {
            let allowed = Set(included.flatMap { symbolsInSystemCategory($0) })
            baseSymbols.formIntersection(allowed)
        }
        if let excluded = excludedIDs {
            let forbidden = Set(excluded.flatMap { symbolsInSystemCategory($0) })
            baseSymbols.subtract(forbidden)
        }
        
        if excludeRestricted {
            let explicitlyIncludedByCustom = Set(customCategories.flatMap { $0.symbols })
            let restrictedSet = Set(restrictedSymbols.keys)
            let restrictedToExclude = restrictedSet.subtracting(explicitlyIncludedByCustom)
            baseSymbols.subtract(restrictedToExclude)
        }
        
        return baseSymbols
            .filter { isAvailable($0, limitVersion: limitVersion) }
            .sorted()
    }
    
    private func symbolsInSystemCategory(_ id: String) -> Set<String> {
        if id == "all" { return Set(allSymbols) }
        var result = Set<String>()
        for (symbol, cats) in symbolToCategories {
            if cats.contains(id) { result.insert(symbol) }
        }
        return result
    }
    
    public func search(
        query: String,
        in symbols: [String],
        customKeywords: [String: [String]] = [:]
    ) -> [String] {
        guard !query.isEmpty else { return symbols }
        let lowQuery = query.lowercased()
        return symbols.filter { symbol in
            if symbol.lowercased().contains(lowQuery) { return true }
            if let keywords = symbolToKeywords[symbol], keywords.contains(where: { $0.lowercased().contains(lowQuery) }) { return true }
            if let custom = customKeywords[symbol], custom.contains(where: { $0.lowercased().contains(lowQuery) }) { return true }
            let cluster = findSymbolCluster(startingWith: symbol)
            if cluster.contains(where: { $0.lowercased().contains(lowQuery) }) { return true }
            return false
        }
    }
}

private extension OperatingSystemVersion {
    init(versionString: String) {
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        self.init(
            majorVersion: components.indices.contains(0) ? components[0] : 0,
            minorVersion: components.indices.contains(1) ? components[1] : 0,
            patchVersion: components.indices.contains(2) ? components[2] : 0
        )
    }
}
