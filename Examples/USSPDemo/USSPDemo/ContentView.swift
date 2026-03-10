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
    
    @State private var isSheetPresented: Bool
    @State private var isPopoverPresented: Bool
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
    
    // tvOS のナビゲーション用
    @State private var navigationPath = NavigationPath()
    
    // プラットフォームごとのレイアウト調整用プロパティ
    private var selectedIconSpacing: CGFloat {
        #if os(tvOS)
        return 30
        #else
        return 8
        #endif
    }
    
    private var selectedIconVerticalPadding: CGFloat {
        #if os(tvOS)
        return 12
        #else
        return 0
        #endif
    }
    
    private var selectedIconTextSpacing: CGFloat {
        #if os(tvOS)
        return 4
        #else
        return 2
        #endif
    }
    
    init(isSheetPresented: Bool = false, isPopoverPresented: Bool = false) {
        self._isSheetPresented = State(initialValue: isSheetPresented)
        self._isPopoverPresented = State(initialValue: isPopoverPresented)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                settingsContent
            }
            .navigationTitle("Picker Demo")
            .formStyle(.grouped)
            #if os(tvOS)
            .navigationDestination(for: String.self) { value in
                if value == "symbol_picker" {
                    SFSymbolPicker(
                        isPresented: .constant(true),
                        selection: $selectedIcon,
                        showAs: .sheet,
                        searchBarPosition: searchBarPosition,
                        showSearchBar: showSearchBar && searchBarStyle == .custom,
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
                    .conditionalSearchable(show: showSearchBar && searchBarStyle == .searchable, text: $searchTextSheet)
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(width: 400, height: 500)
        #elseif os(visionOS)
        .frame(width: 600, height: 800)
        #endif
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        Section {
            #if os(tvOS)
            // データ型 (String) に基づく最新の NavigationLink
            // これにより、システム標準のシェブロンが自動付与され、警告も解消されます。
            NavigationLink(value: "symbol_picker") {
                HStack(spacing: selectedIconSpacing) {
                    if let icon = selectedIcon {
                        Image(systemName: icon, variableValue: variableValue)
                            .font(.headline)
                            .symbolRenderingMode(renderingModeOption.mode)
                            .foregroundStyle(
                                usePrimaryColor ? primaryColor : .primary,
                                useSecondaryColor ? secondaryColor : (usePrimaryColor ? primaryColor : .primary),
                                useTertiaryColor ? tertiaryColor : (usePrimaryColor ? primaryColor : .primary)
                            )
                            .frame(width: 44, height: 44)
                            .padding(.leading, 20)
                        
                        VStack(alignment: .leading, spacing: selectedIconTextSpacing) {
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
                }
                .padding(.vertical, selectedIconVerticalPadding)
                .contentShape(Rectangle())
            }
            #else
            Button {
                if pickerMode == .sheet {
                    isSheetPresented = true
                } else {
                    isPopoverPresented = true
                }
            } label: {
                HStack(spacing: selectedIconSpacing) {
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
                        
                        VStack(alignment: .leading, spacing: selectedIconTextSpacing) {
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
                .padding(.vertical, selectedIconVerticalPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isSheetPresented) {
                NavigationStack {
                    SFSymbolPicker(
                        isPresented: $isSheetPresented,
                        selection: $selectedIcon,
                        showAs: .sheet,
                        searchBarPosition: searchBarPosition,
                        showSearchBar: showSearchBar && searchBarStyle == .custom,
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
                #if os(macOS)
                .frame(width: 600, height: 500)
                #endif
            }
            .popover(isPresented: $isPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                SFSymbolPicker(
                    isPresented: $isPopoverPresented,
                    selection: $selectedIcon,
                    showAs: .popover,
                    searchBarPosition: searchBarPosition,
                    showSearchBar: showSearchBar && searchBarStyle == .custom,
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
            #endif
        } header: {
            Text("Picker Instance")
        }
        
        Section {
            #if !os(tvOS)
            #if os(macOS)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
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
                VStack(alignment: .leading, spacing: 4) {
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
            #endif
            
            Toggle("Show Search Bar", isOn: $showSearchBar)
                #if os(tvOS)
                .padding(.vertical, 8)
                #endif
            
            if showSearchBar {
                #if os(tvOS)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Bar Style")
                        Group {
                            if searchBarStyle == .searchable {
                                Text("Adds a system standard search box using the .searchable modifier.")
                            } else {
                                Text("Adds a custom search box provided by UniversalSFSymbolsPicker.")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $searchBarStyle) {
                        ForEach(SearchBarStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 600)
                }
                .padding(.vertical, 8)
                #elseif os(macOS)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Bar Style")
                        Group {
                            if searchBarStyle == .searchable {
                                Text("Adds a system standard search box using the .searchable modifier.")
                            } else {
                                Text("Adds a custom search box provided by UniversalSFSymbolsPicker.")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Bar Style")
                        Group {
                            if searchBarStyle == .searchable {
                                Text("Adds a system standard search box using the .searchable modifier.")
                            } else {
                                Text("Adds a custom search box provided by UniversalSFSymbolsPicker.")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
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
                
                #if !os(tvOS)
                if searchBarStyle == .custom {
                    #if os(macOS)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Search Bar Position")
                            Text("Select where the search bar is located.")
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
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                    }
                    #else
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Search Bar Position")
                            Text("Select where the search bar is located.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Picker(selection: $searchBarPosition) {
                            Text("Top").tag(SFSymbolPickerSearchBarPosition.top)
                            Text("Bottom").tag(SFSymbolPickerSearchBarPosition.bottom)
                        } label: {
                            Text("Search Bar Position")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    #endif
                }
                #endif
            }
            
            Toggle(isOn: $showCategoryPicker) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Category Picker")
                    Text("Adds a category picker to filter symbols by category.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            #if os(tvOS)
            .padding(.vertical, 8)
            #endif
            
            Toggle(isOn: $showIconName) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Icon Name")
                    Text("Toggle whether to display the name of each symbol.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            #if os(tvOS)
            .padding(.vertical, 8)
            #endif
            
            Toggle(isOn: $excludeRestricted) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exclude Restricted Symbols")
                    Text("Hide symbols with usage restrictions, such as those for Apple services or hardware.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            #if os(tvOS)
            .padding(.vertical, 8)
            #endif
        }
        
        Section {
            #if os(macOS)
            Slider(value: Binding(
                get: { variableValue ?? 0 },
                set: { variableValue = $0 }
            ), in: 0...1) {
                Text("Variable Value: \(variableValue ?? 0, specifier: "%.2f")")
                Text("Specify the value to apply to variable symbols.")
            }
            #elseif os(tvOS)
            Picker(selection: Binding(
                get: { variableValue ?? 0 },
                set: { variableValue = $0 }
            )) {
                ForEach(Array(stride(from: 0.0, through: 1.0, by: 0.1)), id: \.self) { value in
                    Text("\(value, specifier: "%.1f")").tag(value)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Variable Value")
                    Text("Specify the value to apply to variable symbols.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
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
            
            #if os(tvOS)
            Picker(selection: $renderingModeOption) {
                ForEach(RenderingModeOption.allCases) { option in
                    Text(option.rawValue.capitalized).tag(option)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rendering Mode")
                    Text("Select the rendering mode for the symbol.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            #else
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rendering Mode")
                    Text("Select the rendering mode for the symbol.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker(selection: $renderingModeOption) {
                    ForEach(RenderingModeOption.allCases) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                } label: {
                    Text("Rendering Mode")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            #endif
            
            Toggle(isOn: $usePrimaryColor) {
                Text("Primary Color")
            }
            if usePrimaryColor {
                #if !os(tvOS)
                ColorPicker("Select Primary Color", selection: $primaryColor)
                #endif
            }
            
            Toggle(isOn: $useSecondaryColor) {
                Text("Secondary Color")
            }
            if useSecondaryColor {
                #if !os(tvOS)
                ColorPicker("Select Secondary Color", selection: $secondaryColor)
                #endif
            }
            
            Toggle(isOn: $useTertiaryColor) {
                Text("Tertiary Color")
            }
            if useTertiaryColor {
                #if !os(tvOS)
                ColorPicker("Select Tertiary Color", selection: $tertiaryColor)
                #endif
            }
        }
    }
}


#Preview("Default View") {
    ContentView()
}

#Preview("Sheet Presented") {
    ContentView(isSheetPresented: true)
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
