import Foundation
import SwiftUI

/// Represents a category of SF Symbols.
public struct SFSymbolCategory: Identifiable, Hashable {
    public let id: String
    public let label: String
    public let icon: String
}

/// A service that provides access to SF Symbols metadata, availability, categories, and search keywords.
public final class SFSymbolService {
    public static let shared = SFSymbolService()
    
    /// All unique symbol identifiers (canonical names).
    public let allSymbols: [String]
    
    /// All available categories.
    public let categories: [SFSymbolCategory]
    
    /// Internal map: Symbol Name -> Introduction Year
    private let symbolToYear: [String: String]
    
    /// Internal map: Symbol Name -> List of Categories
    private let symbolToCategories: [String: [String]]
    
    /// Internal map: Symbol Name -> List of Keywords
    private let symbolToKeywords: [String: [String]]
    
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
        
        var rev = [String: [String]]()
        for (old, new) in SFSymbolData.aliases {
            rev[new, default: []].append(old)
        }
        self.reverseAliases = rev
        
        let oldAliasSet = Set(SFSymbolData.aliases.keys)
        self.allSymbols = allNames.filter { !oldAliasSet.contains($0) }.sorted()
        
        self.categories = SFSymbolData.categories.map { dict in
            SFSymbolCategory(
                id: dict["id"] ?? "",
                label: dict["label"] ?? "",
                icon: dict["icon"] ?? ""
            )
        }
        
        self.symbolToCategories = SFSymbolData.symbolCategories
        self.symbolToKeywords = SFSymbolData.searchKeywords
    }
    
    /// Finds the best (newest supported) symbol name for the current OS version.
    public func bestName(for name: String) -> String? {
        let cluster = findSymbolCluster(name)
        let sortedCluster = cluster.sorted { nameA, nameB in
            let yearA = symbolToYear[nameA] ?? "0"
            let yearB = symbolToYear[nameB] ?? "0"
            return yearA > yearB
        }
        return sortedCluster.first(where: { isAvailable($0) })
    }
    
    private func findSymbolCluster(_ name: String) -> Set<String> {
        var cluster = Set<String>([name])
        var queue = [name]
        var index = 0
        while index < queue.count {
            let current = queue[index]; index += 1
            if let new = aliases[current], !cluster.contains(new) {
                cluster.insert(new); queue.append(new)
            }
            if let olds = reverseAliases[current] {
                for old in olds where !cluster.contains(old) {
                    cluster.insert(old); queue.append(old)
                }
            }
        }
        return cluster
    }

    /// Checks if a specific symbol name is available on the current platform and OS version.
    public func isAvailable(_ symbol: String) -> Bool {
        guard let year = symbolToYear[symbol] else { return false }
        guard let versions = SFSymbolData.yearToVersion[year] else { return false }
        
        #if os(iOS)
        let currentOS = "iOS"
        #elif os(macOS)
        let currentOS = "macOS"
        #elif os(tvOS)
        let currentOS = "tvOS"
        #elif os(watchOS)
        let currentOS = "watchOS"
        #elif os(visionOS)
        let currentOS = "visionOS"
        #else
        return false
        #endif
        
        guard let requiredVersionString = versions[currentOS] else { return false }
        let requiredVersion = OperatingSystemVersion(versionString: requiredVersionString)
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(requiredVersion)
    }
    
    /// Searches symbols by name or keywords with advanced filtering.
    public func search(
        query: String,
        categoryId: String? = nil,
        sfSymbolsVersion: Double? = nil,
        includedCategories: [String]? = nil,
        excludedCategories: [String]? = nil,
        customKeywords: [String: [String]] = [:]
    ) -> [String] {
        var results = allSymbols
        
        // 1. Filter by SF Symbols Version (Marketing version)
        if let maxVersion = sfSymbolsVersion, let maxYear = SFSymbolData.versionToYear[maxVersion] {
            results = results.filter { symbol in
                guard let introYear = symbolToYear[symbol] else { return false }
                // Lexicographical comparison works for "2024.1" vs "2024.2"
                return introYear <= maxYear
            }
        }
        
        // 2. Filter by global inclusion/exclusion categories
        if let included = includedCategories {
            results = results.filter { symbol in
                let symCats = symbolToCategories[symbol] ?? []
                return !Set(symCats).isDisjoint(with: Set(included))
            }
        }
        
        if let excluded = excludedCategories {
            results = results.filter { symbol in
                let symCats = symbolToCategories[symbol] ?? []
                return Set(symCats).isDisjoint(with: Set(excluded))
            }
        }
        
        // 3. Filter by specific category selection
        if let categoryId = categoryId, categoryId != "all" {
            results = results.filter { symbolToCategories[symbol]?.contains(categoryId) == true }
        }
        
        // 4. Resolve best name for current OS and filter out unavailable ones
        results = results.compactMap { bestName(for: $0) }
        
        // 5. Filter by query (name or keywords)
        if !query.isEmpty {
            let lowerQuery = query.lowercased()
            results = results.filter { symbol in
                if symbol.lowercased().contains(lowerQuery) { return true }
                if let keywords = symbolToKeywords[symbol],
                   keywords.contains(where: { $0.lowercased().contains(lowerQuery) }) {
                    return true
                }
                if let customKws = customKeywords[symbol],
                   customKws.contains(where: { $0.lowercased().contains(lowerQuery) }) {
                    return true
                }
                return false
            }
        }
        
        return results
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
