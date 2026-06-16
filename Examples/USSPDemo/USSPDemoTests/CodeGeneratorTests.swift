import XCTest
@testable import USSPDemo
import UniversalSFSymbolsPicker

final class CodeGeneratorTests: XCTestCase {

    func testMandatoryOptionsOnly() throws {
        var options = BuildModeOptions()
        options.enableDisplayMode = true
        options.enableControlBarPosition = true
        
        let code = CodeGenerator.generate(options: options)
        
        // Not wrapped in NavigationStack by default
        XCTAssertFalse(code.contains("NavigationStack {"))
        XCTAssertTrue(code.contains("showAs: .sheet"))
        XCTAssertTrue(code.contains("controlBarPosition: .bottom"))
        XCTAssertFalse(code.contains(".searchable(text: $searchText)"))
    }
    
    func testShowSearchBarDisabled() throws {
        var options = BuildModeOptions()
        options.enableShowSearchBar = true
        options.showSearchBar = false
        let code = CodeGenerator.generate(options: options)
        
        // NavigationStack and searchable should be removed
        XCTAssertFalse(code.contains("NavigationStack {"))
        XCTAssertFalse(code.contains(".searchable(text: $searchText)"))
        XCTAssertTrue(code.contains("showSearchBar: false"))
    }
    
    func testUseSearchable() throws {
        var options = BuildModeOptions()
        options.useSearchable = true
        let code = CodeGenerator.generate(options: options)
        
        // NavigationStack and searchable should be added, with showSearchBar: false
        XCTAssertTrue(code.contains("NavigationStack {"))
        XCTAssertTrue(code.contains(".searchable(text: $searchText)"))
        XCTAssertTrue(code.contains("showSearchBar: false"))
        XCTAssertFalse(code.contains("searchText: $searchText")) // Not passed as an argument
    }
    
    func testBooleanOverrides() throws {
        var options = BuildModeOptions()
        options.enableShowCategoryPicker = true
        options.showCategoryPicker = false
        options.enableShowIconName = true
        options.showIconName = false
        options.enableExcludeRestricted = true
        options.excludeRestricted = true
        options.enableIsGradient = true
        options.isGradient = true
        
        let code = CodeGenerator.generate(options: options)
        XCTAssertTrue(code.contains("showCategoryPicker: false"))
        XCTAssertTrue(code.contains("showIconName: false"))
        XCTAssertTrue(code.contains("excludeRestricted: true"))
        XCTAssertTrue(code.contains("isGradient: true"))
    }
    
    func testValueOverrides() throws {
        var options = BuildModeOptions()
        options.enableIconScale = true
        options.iconScale = 8
        options.enableRenderingMode = true
        options.renderingModeOption = .multicolor
        
        let code = CodeGenerator.generate(options: options)
        XCTAssertTrue(code.contains("iconScale: 8"))
        XCTAssertTrue(code.contains("renderingMode: .multicolor"))
    }
}
