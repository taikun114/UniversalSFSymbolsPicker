import Testing
import Foundation
@testable import UniversalSFSymbolsPicker

@Suite("SFSymbolService Tests")
struct SFSymbolServiceTests {
    let service = SFSymbolService.shared

    @Test("Metadata initialization")
    func testInitialization() {
        #expect(!service.allSymbols.isEmpty)
        #expect(!service.systemCategories.isEmpty)
        #expect(service.systemCategories.contains(where: { $0.id == "all" }))
        #expect(service.systemCategories.contains(where: { $0.id == "weather" }))
    }

    @Test("Symbol availability")
    func testAvailability() {
        // "star.fill" is a very basic symbol available since the beginning
        #expect(service.isAvailable("star.fill"))
        
        // Check availability with a version limit (e.g., version 1.0 which is 2019)
        #expect(service.isAvailable("star.fill", limitVersion: 1.0))
        
        // Symbols introduced later should not be available if limitVersion is too low.
        // For example, "fan.oscillation" was introduced in SF Symbols 4.0 (2022)
        // Note: We check if it exists in allSymbols first to ensure our data has it.
        if service.allSymbols.contains("fan.oscillation") {
            #expect(!service.isAvailable("fan.oscillation", limitVersion: 1.0))
            #expect(service.isAvailable("fan.oscillation", limitVersion: 4.0))
        }
    }

    @Test("Effective name and alias resolution")
    func testEffectiveName() {
        // "applelogo" is an old name for "apple.logo"
        #expect(service.effectiveName(for: "applelogo") == "apple.logo")
        
        // "auto.brakesignal" -> "automatic.brakesignal"
        #expect(service.effectiveName(for: "auto.brakesignal") == "automatic.brakesignal")
        
        // Test version fallback based on actual data:
        // "arrow.clockwise.heart" was introduced in 2.0 (2020)
        // Its newer name "arrow.trianglehead.clockwise.heart" was introduced in 6.0 (2024)
        if service.allSymbols.contains("arrow.trianglehead.clockwise.heart") {
            // New behavior: even if we limit to 2.0, if the current OS supports 6.0, 
            // effectiveName should return the latest name "arrow.trianglehead.clockwise.heart" 
            // because the symbol itself was known in 2.0 (as arrow.clockwise.heart).
            let name20 = service.effectiveName(for: "arrow.trianglehead.clockwise.heart", limitVersion: 2.0)
            
            // Since we are running on a recent macOS (26.3.1), it should return the latest name.
            #expect(name20 == "arrow.trianglehead.clockwise.heart")
            
            // On the same OS, limitVersion 6.0 also returns the latest name.
            let name60 = service.effectiveName(for: "arrow.clockwise.heart", limitVersion: 6.0)
            #expect(name60 == "arrow.trianglehead.clockwise.heart")
        }
    }

    @Test("Filtering by category")
    func testFiltering() {
        // Test "all" category
        let all = service.symbols(for: "all")
        
        // Account for locale filtering which happens inside service.symbols(for: "all")
        let symbolVariants: Set<String> = ["ar", "hi", "he", "zh", "th", "ja", "ko", "el", "ru", "my", "km", "bn", "gu", "kn", "ml", "mr", "or", "pa", "si", "ta", "te", "sat", "mni", "rtl"]
        let expectedCount = service.allSymbols.filter { name in
            guard service.isAvailable(name) else { return false }
            let components = name.lowercased().components(separatedBy: ".")
            return !components.contains { symbolVariants.contains($0) }
        }.count
        
        #expect(all.count == expectedCount)
        
        // Test "weather" category
        let weather = service.symbols(for: "weather")
        #expect(!weather.isEmpty)
        #expect(weather.contains("sun.max.fill"))
        
        // Test restricted symbols exclusion
        // "apple.logo" is a restricted symbol (canonical name)
        let restrictedExcluded = service.symbols(for: "all", excludeRestricted: true)
        let restrictedIncluded = service.symbols(for: "all", excludeRestricted: false)
        #expect(restrictedIncluded.contains("apple.logo"))
        #expect(!restrictedExcluded.contains("apple.logo"))
    }

    @Test("Custom categories")
    func testCustomCategories() {
        let customID = UUID()
        let customCat = CustomCategory(
            id: customID,
            label: "Test",
            icon: "star",
            symbols: ["star.fill", "heart.fill"],
            systemCategories: ["weather"]
        )
        
        let symbols = service.symbols(for: customID.uuidString, customCategories: [customCat])
        
        #expect(symbols.contains("star.fill"))
        #expect(symbols.contains("heart.fill"))
        // Should also contain weather symbols
        #expect(symbols.contains("sun.max.fill"))
    }

    @Test("Search functionality and multi-category coverage")
    func testSearch() {
        let weatherSymbols = service.symbols(for: "weather")
        
        // Search for "sun" in weather
        let results = service.search(query: "sun", in: weatherSymbols)
        #expect(!results.isEmpty)
        #expect(results.contains("sun.max.fill"))
        
        // Search across "all" symbols
        let allSymbols = service.symbols(for: "all")
        let globalResults = service.search(query: "cloud", in: allSymbols)
        #expect(globalResults.contains("cloud.fill"))
        #expect(globalResults.contains("cloud.sun.fill")) // This is in weather category
        
        // Search by alias: searching for "applelogo" should find "apple.logo"
        let aliasSearchResults = service.search(query: "applelogo", in: allSymbols)
        #expect(aliasSearchResults.contains("apple.logo"))
        
        // Custom keywords search
        let customKeywords = ["star.fill": ["favorite", "important"]]
        let searchWithKeywords = service.search(query: "favorite", in: ["star.fill"], customKeywords: customKeywords)
        #expect(searchWithKeywords.contains("star.fill"))
    }
    
    @Test("Locale filtering")
    func testLocaleFiltering() {
        // Symbols with .ja or .ar etc. should be filtered out by default in service.symbols()
        let all = service.symbols(for: "all")
        
        // Check for symbols that SHOULD be filtered out
        let jaSymbols = all.filter { name in
            let components = name.lowercased().components(separatedBy: ".")
            return components.contains("ja")
        }
        #expect(jaSymbols.isEmpty)
        
        let arSymbols = all.filter { name in
            let components = name.lowercased().components(separatedBy: ".")
            return components.contains("ar")
        }
        #expect(arSymbols.isEmpty)
        
        // Ensure "audio.jack.mono" is NOT filtered out (it has .jack, not .ja)
        if service.allSymbols.contains("audio.jack.mono") {
            #expect(all.contains("audio.jack.mono"))
        }
    }

    @Test("Exclusion priority between 'all' and custom categories")
    func testExclusionPriority() {
        // 1. Define a "Hidden" category to act as a global exclusion filter
        let hiddenID = UUID()
        let hiddenCat = CustomCategory(
            id: hiddenID,
            label: "Hidden",
            icon: "xmark",
            symbols: ["figure.wave"]
        )
        
        // 2. Define a "Custom Map" category that explicitly includes the excluded icon
        let mapID = UUID()
        let customMap = CustomCategory(
            id: mapID,
            label: "Custom Map",
            icon: "map",
            symbols: ["figure.wave"], // Explicitly "rescues" the icon
            systemCategories: ["maps"]
        )
        
        let customCategories = [hiddenCat, customMap]
        let excludedIDs = [hiddenID.uuidString]
        
        // CASE A: 'all' category
        let allSymbols = service.symbols(
            for: "all",
            customCategories: customCategories,
            excludedIDs: excludedIDs
        )
        // figure.wave should be ABSENT in 'all' because it's in the excluded list
        #expect(!allSymbols.contains("figure.wave"))
        
        // CASE B: 'Custom Map' category
        let mapSymbols = service.symbols(
            for: mapID.uuidString,
            customCategories: customCategories,
            excludedIDs: excludedIDs
        )
        // figure.wave should be PRESENT here because it's explicitly in the 'symbols' array
        #expect(mapSymbols.contains("figure.wave"))
    }

    @Test("CustomCategory independent excludedSymbols")
    func testCustomCategoryExcludedSymbols() {
        let customID = UUID()
        let customCat = CustomCategory(
            id: customID,
            label: "Test",
            icon: "star",
            systemCategories: ["nature"],
            excludedSymbols: ["leaf.fill"] // should be removed from the list
        )
        
        let symbols = service.symbols(for: customID.uuidString, customCategories: [customCat])
        
        // 1. Other nature symbols should be present
        #expect(symbols.contains("ant.fill"))
        // 2. The specifically excluded symbol should be absent
        #expect(!symbols.contains("leaf.fill"))
    }

    @Test("Completely empty custom category")
    func testEmptyCategory() {
        let emptyID = UUID()
        let emptyCat = CustomCategory(
            id: emptyID,
            label: "Empty",
            icon: "circle",
            symbols: [],
            systemCategories: [],
            excludedSymbols: []
        )
        
        let symbols = service.symbols(for: emptyID.uuidString, customCategories: [emptyCat])
        
        // Should be completely empty
        #expect(symbols.isEmpty)
    }
}
