import Foundation
import SwiftUI

/// Represents a category of SF Symbols.
public struct SFSymbolCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let icon: String
}

/// Internal structure for decoding JSON metadata.
private struct SymbolMetadata: Codable {
    let bundleVersion: String
    let latestYear: String
    let versionToYear: [String: String]
    let yearToVersion: [String: [String: String]]
    let categories: [[String: String]]
    let aliases: [String: String]
    let symbolCategories: [String: [String]]
    let symbolAvailability: [String: [String]]
    let searchKeywords: [String: [String]]
    let restrictedSymbols: [String: String]
}

/// A service that provides access to SF Symbols metadata, availability, categories, and search keywords.
public final class SFSymbolService: Sendable {
    public static let shared = SFSymbolService()
    
    /// All unique symbol identifiers (canonical names).
    public let allSymbols: [String]
    
    /// All available system categories.
    public let systemCategories: [SFSymbolCategory]
    
    /// Internal metadata storage
    private let metadata: SymbolMetadata?
    
    /// Internal map: Symbol Name -> Introduction Year
    private let symbolToYear: [String: String]
    
    /// Internal map: New Name -> [Old Names]
    private let reverseAliases: [String: [String]]
    
    private init() {
        // Load JSON from bundle
        guard let url = Bundle.module.url(forResource: "SFSymbolData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SymbolMetadata.self, from: data) else {
            self.metadata = nil
            self.allSymbols = []
            self.systemCategories = []
            self.symbolToYear = [:]
            self.reverseAliases = [:]
            return
        }
        
        self.metadata = decoded
        
        var allNames = [String]()
        var lookupYear = [String: String]()
        for (year, symbols) in decoded.symbolAvailability {
            allNames.append(contentsOf: symbols)
            for symbol in symbols {
                lookupYear[symbol] = year
            }
        }
        
        self.symbolToYear = lookupYear
        
        // Build reverse aliases for fallback lookup
        var rev = [String: [String]]()
        for (old, new) in decoded.aliases {
            rev[new, default: []].append(old)
        }
        self.reverseAliases = rev
        
        // Canonical symbols are those that are NOT an old alias for something else
        let oldAliasSet = Set(decoded.aliases.keys)
        self.allSymbols = allNames.filter { !oldAliasSet.contains($0) }.sorted()
        
        self.systemCategories = decoded.categories.map { dict in
            SFSymbolCategory(
                id: dict["id"] ?? "",
                label: dict["label"] ?? "",
                icon: dict["icon"] ?? ""
            )
        }
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
            if let new = metadata?.aliases[current], !cluster.contains(new) {
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
        // 1. 指定された名前そのものが利用可能かチェック
        if checkIndividualAvailability(symbol, limitVersion: limitVersion) {
            return true
        }

        // 2. エイリアス（仲間）の中に、現在の OS で利用可能なものがあるかチェック
        // これにより、最新名が v26+ でも、旧名が v17+ であれば、OS 17 環境でリストに残るようになる
        let cluster = findSymbolCluster(startingWith: symbol)
        return cluster.contains { checkIndividualAvailability($0, limitVersion: limitVersion) }
    }

    private func checkIndividualAvailability(_ symbol: String, limitVersion: Double? = nil) -> Bool {
        guard let year = symbolToYear[symbol] else { return false }
        if let limit = limitVersion, let limitYear = metadata?.versionToYear[String(limit)] {
            if year.compare(limitYear, options: .numeric) == .orderedDescending { return false }
        }
        guard let versions = metadata?.yearToVersion[year] else { return false }

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
            let restrictedSet = Set(metadata?.restrictedSymbols.keys.map { String($0) } ?? [])
            let restrictedToExclude = restrictedSet.subtracting(explicitlyIncludedByCustom)
            baseSymbols.subtract(restrictedToExclude)
        }
        // 2文字だがロケールではなく意味のある単語（ホワイトリスト）
        let nonLocaleTwoLetterWords: Set<String> = [
            "up", "on", "go", "tv", "pc", "3d", "ex", "of", "to", "in", "by", "at", "as",
            "ac", "dc", "lc", "or", "no", "re", "pi"
        ]
        
        return baseSymbols
            .filter { name in
                let components = name.lowercased().components(separatedBy: ".")
                return !components.contains { component in
                    // 2文字の要素があり、かつそれがホワイトリストに含まれていない場合はロケールと判断
                    component.count == 2 && !nonLocaleTwoLetterWords.contains(component)
                }
            }
            .filter { isAvailable($0, limitVersion: limitVersion) }
            .sorted()
    }
    
    private func symbolsInSystemCategory(_ id: String) -> Set<String> {
        if id == "all" { return Set(allSymbols) }
        var result = Set<String>()
        guard let symbolCategories = metadata?.symbolCategories else { return result }
        for (symbol, cats) in symbolCategories {
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
            if let keywords = metadata?.searchKeywords[symbol], keywords.contains(where: { $0.lowercased().contains(lowQuery) }) { return true }
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
