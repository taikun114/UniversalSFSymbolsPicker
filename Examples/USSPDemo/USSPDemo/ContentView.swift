import SwiftUI
import UniversalSFSymbolsPicker

// SymbolRenderingMode は Hashable ではないため、デモ用にラップする enum を定義
enum RenderingModeOption: String, CaseIterable, Identifiable {
    case monochrome, hierarchical, palette, multicolor
    var id: String { rawValue }
    
    var mode: SymbolRenderingMode {
        switch self {
        case .monochrome: return .monochrome
        case .hierarchical: return .hierarchical
        case .palette: return .palette
        case .multicolor: return .multicolor
        }
    }
}

enum SearchBarStyle: String, CaseIterable, Identifiable {
    case searchable = ".searchable"
    case custom = "Custom"
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var selectedIcon: String? = "star.fill"
    @State private var pickerMode: SFSymbolPickerDisplayMode = .sheet
    @State private var searchBarPosition: SFSymbolPickerSearchBarPosition = .bottom
    @State private var showSearchBar = true
    @State private var searchBarStyle: SearchBarStyle = .searchable
    @State private var searchTextSheet = ""
    @State private var searchTextPopover = ""
    
    @State private var isSheetPresented = false
    @State private var isPopoverPresented = false
    @State private var showIconName = true
    @State private var showCategoryPicker = true
    
    // デモ用の設定
    @State private var variableValue: Double? = 1.0
    @State private var renderingModeOption: RenderingModeOption = .monochrome
    @State private var primaryColor: Color = .blue
    @State private var secondaryColor: Color = .red
    @State private var tertiaryColor: Color = .green
    @State private var usePrimaryColor = false
    @State private var useSecondaryColor = false
    @State private var useTertiaryColor = false
    @State private var excludeRestricted = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        if pickerMode == .sheet {
                            isSheetPresented = true
                        } else {
                            isPopoverPresented = true
                        }
                    } label: {
                        HStack(spacing: 16) {
                            if let icon = selectedIcon {
                                Image(systemName: icon, variableValue: variableValue)
                                    .font(.title)
                                    .symbolRenderingMode(renderingModeOption.mode)
                                    .foregroundStyle(
                                        usePrimaryColor ? primaryColor : .primary,
                                        useSecondaryColor ? secondaryColor : (usePrimaryColor ? primaryColor : .primary),
                                        useTertiaryColor ? tertiaryColor : (usePrimaryColor ? primaryColor : .primary)
                                    )
                                    .frame(width: 44, height: 44)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Selected Icon")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(icon)
                                        .font(.body.monospaced())
                                }
                            } else {
                                Label("Select an Icon", systemImage: "plus.circle")
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle()) // 全体をタップ可能にする
                    }
                    .buttonStyle(.plain)
                    // ポップオーバーとシートをボタンに紐付け
                    .sheet(isPresented: $isSheetPresented) {
                        NavigationStack {
                            SFSymbolPicker(
                                isPresented: $isSheetPresented,
                                selection: $selectedIcon,
                                showAs: .sheet,
                                searchBarPosition: searchBarPosition, // ここを追加
                                showSearchBar: showSearchBar && searchBarStyle == .custom, // カスタム時のみ
                                showCategoryPicker: showCategoryPicker,
                                showIconName: showIconName,
                                excludeRestricted: excludeRestricted,
                                renderingMode: renderingModeOption.mode,
                                primaryColor: usePrimaryColor ? primaryColor : .primary,
                                secondaryColor: useSecondaryColor ? secondaryColor : nil,
                                tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                                variableValue: $variableValue,
                                searchText: $searchTextSheet
                            )
                        }
                        .conditionalSearchable(show: showSearchBar && searchBarStyle == .searchable, text: $searchTextSheet)
                    }
                    .popover(isPresented: $isPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        SFSymbolPicker(
                            isPresented: $isPopoverPresented,
                            selection: $selectedIcon,
                            showAs: .popover,
                            searchBarPosition: searchBarPosition,
                            showSearchBar: showSearchBar && searchBarStyle == .custom, // カスタム時のみ
                            showCategoryPicker: showCategoryPicker,
                            showIconName: showIconName,
                            excludeRestricted: excludeRestricted,
                            renderingMode: renderingModeOption.mode,
                            primaryColor: usePrimaryColor ? primaryColor : .primary,
                            secondaryColor: useSecondaryColor ? secondaryColor : nil,
                            tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                            variableValue: $variableValue,
                            searchText: $searchTextPopover
                        )
                    }
                } header: {
                    Text("Picker Instance")
                }
                
                Section("Settings") {
                    #if os(macOS)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Display Mode")
                            Text("Select how the symbol picker is presented.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker(selection: $pickerMode) {
                            Text("Sheet").tag(SFSymbolPickerDisplayMode.sheet)
                            Text("Popover").tag(SFSymbolPickerDisplayMode.popover)
                        } label: {
                            Text("Display Mode")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                    }
                    #else
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading) {
                            Text("Display Mode")
                            Text("Select how the symbol picker is presented.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Picker(selection: $pickerMode) {
                            Text("Sheet").tag(SFSymbolPickerDisplayMode.sheet)
                            Text("Popover").tag(SFSymbolPickerDisplayMode.popover)
                        } label: {
                            Text("Display Mode")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    #endif
                    
                    Toggle("Show Search Bar", isOn: $showSearchBar)
                    
                    if showSearchBar {
                        #if os(macOS)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Search Bar Style")
                                if searchBarStyle == .searchable {
                                    Text("Adds a system standard search box using the .searchable modifier.")
                                } else {
                                    Text("Adds a custom search box provided by UniversalSFSymbolsPicker.")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Spacer()
                            Picker(selection: $searchBarStyle) {
                                ForEach(SearchBarStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            } label: {
                                Text("Search Bar Style")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .fixedSize()
                        }
                        #else
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading) {
                                Text("Search Bar Style")
                                if searchBarStyle == .searchable {
                                    Text("Adds a system standard search box using the .searchable modifier.")
                                } else {
                                    Text("Adds a custom search box provided by UniversalSFSymbolsPicker.")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Picker(selection: $searchBarStyle) {
                                ForEach(SearchBarStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            } label: {
                                Text("Search Bar Style")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        #endif
                        
                        if searchBarStyle == .custom {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Search Bar Position")
                                    Text("Set the position where the search box and category picker will appear.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Picker(selection: $searchBarPosition) {
                                    Text("Top").tag(SFSymbolPickerSearchBarPosition.top)
                                    Text("Bottom").tag(SFSymbolPickerSearchBarPosition.bottom)
                                } label: {
                                    Text("Search Bar Position")
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                        }
                    }
                    
                    Toggle(isOn: $showCategoryPicker) {
                        Text("Show Category Picker")
                        Text("Adds a category picker to filter symbols by category.")
                    }
                    
                    Toggle(isOn: $showIconName) {
                        Text("Show Icon Name")
                        Text("Toggle whether to display the name of each symbol.")
                    }
                    
                    Toggle(isOn: $excludeRestricted) {
                        Text("Exclude Restricted Symbols")
                        Text("Hide symbols with usage restrictions, such as those for Apple services or hardware.")
                    }
                }
                
                Section("Dynamic Rendering Demo") {
                    #if os(macOS)
                    Slider(value: Binding(
                        get: { variableValue ?? 0 },
                        set: { variableValue = $0 }
                    ), in: 0...1) {
                        Text("Variable Value: \(variableValue ?? 0, specifier: "%.2f")")
                        Text("Specify the value to apply to variable symbols.")
                    }
                    #else
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Variable Value: \(variableValue ?? 0, specifier: "%.2f")")
                        Slider(value: Binding(
                            get: { variableValue ?? 0 },
                            set: { variableValue = $0 }
                        ), in: 0...1)
                        Text("Specify the value to apply to variable symbols.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    #endif
                    
                    Picker("Rendering Mode", selection: $renderingModeOption) {
                        ForEach(RenderingModeOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }
                    
                    Group {
                        Toggle(isOn: $usePrimaryColor) {
                            HStack {
                                Text("Primary Color")
                                if usePrimaryColor {
                                    Spacer()
                                    ColorPicker("", selection: $primaryColor)
                                        .labelsHidden()
                                        .fixedSize()
                                }
                            }
                        }
                        
                        Toggle(isOn: $useSecondaryColor) {
                            HStack {
                                Text("Secondary Color")
                                if useSecondaryColor {
                                    Spacer()
                                    ColorPicker("", selection: $secondaryColor)
                                        .labelsHidden()
                                        .fixedSize()
                                }
                            }
                        }
                        
                        Toggle(isOn: $useTertiaryColor) {
                            HStack {
                                Text("Tertiary Color")
                                if useTertiaryColor {
                                    Spacer()
                                    ColorPicker("", selection: $tertiaryColor)
                                        .labelsHidden()
                                        .fixedSize()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Picker Demo")
            .formStyle(.grouped)
        }
        #if os(macOS)
        .frame(width: 400, height: 500)
        #elseif os(visionOS)
        // ナビゲーションバー等を含めた全体のサイズを固定
        .frame(width: 600, height: 800)
        #endif
    }
}


#Preview {
    ContentView()
}

// MARK: - Helper Extension

private extension View {
    @ViewBuilder
    func conditionalSearchable(show: Bool, text: Binding<String>) -> some View {
        if show {
            self.searchable(text: text, prompt: "Search icons in sheet...")
        } else {
            self
        }
    }
}
