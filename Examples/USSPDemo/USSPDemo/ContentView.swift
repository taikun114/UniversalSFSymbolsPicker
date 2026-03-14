import SwiftUI
import UniversalSFSymbolsPicker

// SymbolRenderingMode は Hashable ではないため、デモ用にラップする enum を定義
enum RenderingModeOption: String, CaseIterable, Identifiable {
    case monochrome, hierarchical, palette, multicolor
    var id: String { rawValue }
    
    var label: LocalizedStringKey {
        switch self {
        case .monochrome: return "Monochrome"
        case .hierarchical: return "Hierarchical"
        case .palette: return "Palette"
        case .multicolor: return "Multicolor"
        }
    }
    
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
    
    var label: LocalizedStringKey {
        switch self {
        case .searchable: return ".searchable"
        case .custom: return "Custom"
        }
    }
}

struct ContentView: View {
    @State private var selectedIcon: String? = "star.fill"
    @State private var pickerMode: SFSymbolPickerDisplayMode = .sheet
    @State private var controlBarPosition: SFSymbolPickerControlBarPosition = .bottom
    @State private var showSearchBar = true
    @State private var searchBarStyle: SearchBarStyle = .searchable
    @State private var searchTextSheet = ""
    @State private var searchTextPopover = ""
    
    @State private var isSheetPresented: Bool
    @State private var isPopoverPresented: Bool
    @State private var showIconName = true
    @State private var showCategoryPicker = true
    @State private var showCategorySectionLabel = true
    @State private var categoryLabelVisibility: SFSymbolPickerCategoryLabelVisibility = .default
    @State private var categoryLabelStyle: SFSymbolPickerCategoryLabelStyle = .both
    
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
    
    // Custom Categories for Demo
    private let demoCustomCategories = [
        CustomCategory(
            label: String(localized: "Demo Category 1 (Random)"),
            icon: "test.for.non.existent.icon",
            symbols: [
                "square.and.arrow.up", "pencil", "eraser", "trash", "paperplane",
                "tray.circle", "shareplay", "aqi.medium", "highlighter.badge.ellipsis",
                "paperplane.circle.fill", "widget.extralarge.badge.plus", "bolt.square",
                "camera.fill", "plus.viewfinder", "sunset", "moonphase.waning.gibbous",
                "test.for.non.existent.icon", "apple.classical.pages", "a"
            ]
        ),
        CustomCategory(
            label: String(localized: "Demo Category 2"),
            icon: "desktopcomputer.and.macbook",
            symbols: [
                "desktopcomputer", "macpro.gen1", "macpro.gen2", "macpro.gen3", "macpro.gen3.server",
                "macbook.gen1", "macbook.gen2", "macbook", "macbook.and.iphone", "macbook.and.ipad",
                "macbook.and.applewatch", "macbook.and.ipod", "macmini", "macmini.gen2", "macmini.gen3",
                "macstudio", "macbook.sizes", "macbook.gen1.sizes", "macbook.gen2.sizes", "macbook.and.vision.pro"
            ]
        ),
        CustomCategory(
            label: String(localized: "Demo Category 3 (Maps + Transportation + star.fill)"),
            icon: "map",
            symbols: ["star.fill"],
            systemCategories: ["maps", "transportation"]
        )
    ]
    
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
        NavigationStack {
            Form {
                settingsContent
            }
            .navigationTitle("Picker Demo")
            .formStyle(.grouped)
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
            NavigationLink {
                SFSymbolPicker(
                    isPresented: .constant(true),
                    selection: $selectedIcon,
                    showAs: .sheet,
                    controlBarPosition: controlBarPosition,
                    showSearchBar: showSearchBar && searchBarStyle == .custom,
                    showCategoryPicker: showCategoryPicker,
                    showCategorySectionLabel: showCategorySectionLabel,
                    categoryLabelVisibility: categoryLabelVisibility,
                    categoryLabelStyle: categoryLabelStyle,
                    showIconName: showIconName,
                    customCategories: demoCustomCategories,
                    excludeRestricted: excludeRestricted,
                    renderingMode: renderingModeOption.mode,
                    primaryColor: usePrimaryColor ? primaryColor : .primary,
                    secondaryColor: useSecondaryColor ? secondaryColor : nil,
                    tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                    variableValue: $variableValue,
                    searchText: $searchTextSheet
                )
                .conditionalSearchable(show: showSearchBar && searchBarStyle == .searchable, text: $searchTextSheet)
            } label: {
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
                        controlBarPosition: controlBarPosition,
                        showSearchBar: showSearchBar && searchBarStyle == .custom,
                        showCategoryPicker: showCategoryPicker,
                        showCategorySectionLabel: showCategorySectionLabel,
                        categoryLabelVisibility: categoryLabelVisibility,
                        categoryLabelStyle: categoryLabelStyle,
                        showIconName: showIconName,
                        customCategories: demoCustomCategories,
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
                    controlBarPosition: controlBarPosition,
                    showSearchBar: showSearchBar && searchBarStyle == .custom,
                    showCategoryPicker: showCategoryPicker,
                    showCategorySectionLabel: showCategorySectionLabel,
                    categoryLabelVisibility: categoryLabelVisibility,
                    categoryLabelStyle: categoryLabelStyle,
                    showIconName: showIconName,
                    customCategories: demoCustomCategories,
                    excludeRestricted: excludeRestricted,
                    renderingMode: renderingModeOption.mode,
                    primaryColor: usePrimaryColor ? primaryColor : .primary,
                    secondaryColor: useSecondaryColor ? secondaryColor : nil,
                    tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                    variableValue: $variableValue,
                    searchText: $searchTextPopover
                )
                #if os(macOS)
                .frame(width: 360, height: 500)
                #elseif os(visionOS)
                .frame(width: 440, height: 540)
                #endif
            }
            #endif
        } header: {
            Text("Picker Instance")
        }
        
        Section {
            #if !os(tvOS)
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
                .adaptiveButtonSizingFlexible()
            }
            
            if pickerMode == .popover || searchBarStyle == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Control Bar Position")
                        Text("Select where the search bar and category picker are located.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Picker(selection: $controlBarPosition) {
                        Text("Top").tag(SFSymbolPickerControlBarPosition.top)
                        Text("Bottom").tag(SFSymbolPickerControlBarPosition.bottom)
                    } label: {
                        Text("Control Bar Position")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .adaptiveButtonSizingFlexible()
                }
            }
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
                    Picker(selection: $searchBarStyle) {
                        ForEach(SearchBarStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    } label: {
                        Text("Search Bar Style")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 900)
                }
                .padding(.vertical, 8)
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
                            Text(style.label).tag(style)
                        }
                    } label: {
                        Text("Search Bar Style")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .adaptiveButtonSizingFlexible()
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
            
            if showCategoryPicker {
                Toggle(isOn: $showCategorySectionLabel) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show Category Section Label")
                        Text("Toggle whether to display section headers in the category menu (iOS 18.0+, macOS 15.0+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                #if os(tvOS)
                .padding(.vertical, 8)
                #endif
                
                #if os(tvOS)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category Label Visibility")
                        Text("Select how the category label is displayed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker(selection: $categoryLabelVisibility) {
                        Text("Default").tag(SFSymbolPickerCategoryLabelVisibility.default)
                        Text("Visible").tag(SFSymbolPickerCategoryLabelVisibility.visible)
                        Text("Hidden").tag(SFSymbolPickerCategoryLabelVisibility.hidden)
                    } label: {
                        Text("Category Label Visibility")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 900)
                }
                .padding(.vertical, 8)
                
                if categoryLabelVisibility != .hidden {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category Label Style")
                            Text("Select the style of the category label.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker(selection: $categoryLabelStyle) {
                            Text("Both").tag(SFSymbolPickerCategoryLabelStyle.both)
                            Text("Title Only").tag(SFSymbolPickerCategoryLabelStyle.titleOnly)
                            Text("Name Only").tag(SFSymbolPickerCategoryLabelStyle.nameOnly)
                        } label: {
                            Text("Category Label Style")
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 900)
                    }
                    .padding(.vertical, 8)
                }
                #else
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category Label Visibility")
                        Text("Select how the category label is displayed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Picker(selection: $categoryLabelVisibility) {
                        Text("Default").tag(SFSymbolPickerCategoryLabelVisibility.default)
                        Text("Visible").tag(SFSymbolPickerCategoryLabelVisibility.visible)
                        Text("Hidden").tag(SFSymbolPickerCategoryLabelVisibility.hidden)
                    } label: {
                        Text("Category Label Visibility")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .adaptiveButtonSizingFlexible()
                }
                
                if categoryLabelVisibility != .hidden {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category Label Style")
                            Text("Select the style of the category label.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Picker(selection: $categoryLabelStyle) {
                            Text("Both").tag(SFSymbolPickerCategoryLabelStyle.both)
                            Text("Title Only").tag(SFSymbolPickerCategoryLabelStyle.titleOnly)
                            Text("Name Only").tag(SFSymbolPickerCategoryLabelStyle.nameOnly)
                        } label: {
                            Text("Category Label Style")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .adaptiveButtonSizingFlexible()
                    }
                }
                #endif
            }
            
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
        } header: {
            Text("Settings")
        }
        
        Section {
            #if os(macOS)
            Slider(value: Binding(
                get: { variableValue ?? 0 },
                set: { variableValue = $0 }
            ), in: 0...1) {
                HStack(spacing: 0) {
                    Text("Variable Value: ")
                    Text(variableValue ?? 0, format: .number.precision(.fractionLength(2)))
                }
                Text("Specify the value to apply to variable symbols.")
            }
            #elseif os(tvOS)
            Picker(selection: Binding(
                get: { variableValue ?? 0 },
                set: { variableValue = $0 }
            )) {
                ForEach(Array(stride(from: 0.0, through: 1.0, by: 0.1)), id: \.self) { value in
                    Text(value, format: .number.precision(.fractionLength(1))).tag(value)
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
                HStack(spacing: 0) {
                    Text("Variable Value: ")
                    Text(variableValue ?? 0, format: .number.precision(.fractionLength(2)))
                }
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rendering Mode")
                    Text("Select the rendering mode for the symbol.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $renderingModeOption) {
                    ForEach(RenderingModeOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 1000)
            }
            .padding(.vertical, 8)
            #else
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rendering Mode")
                    Text("Select the rendering mode for the symbol.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Picker(selection: $renderingModeOption) {
                    ForEach(RenderingModeOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                } label: {
                    Text("Rendering Mode")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .adaptiveButtonSizingFlexible()
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
        } header: {
            Text("Dynamic Rendering Demo")
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
    
    @ViewBuilder
    func adaptiveButtonSizingFlexible() -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            self.buttonSizing(.flexible)
        } else {
            self
        }
    }
}
