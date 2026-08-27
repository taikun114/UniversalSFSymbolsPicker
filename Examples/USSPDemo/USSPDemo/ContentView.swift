import SwiftUI
import UniversalSFSymbolsPicker

// Wrapper enum for SymbolRenderingMode since it is not Hashable
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
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
    
    @State private var isVisionOSBuildModePresented = false
    
    // Demo settings
    @State private var variableValue: Double? = 1.0
    @State private var renderingModeOption: RenderingModeOption = .monochrome
    @State private var isGradient = false
    @State private var primaryColor: Color = .blue
    @State private var secondaryColor: Color = .red
    @State private var tertiaryColor: Color = .green
    @State private var usePrimaryColor = false
    @State private var useSecondaryColor = false
    @State private var useTertiaryColor = false
    @State private var excludeRestricted = false
    @State private var iconScale: Int = 5
    @State private var iconSpacing: Int = 5
    @State private var showRecents = false
    @State private var maxRecents = 20
    
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
        ),
        CustomCategory(
            label: String(localized: "Exclusion Filter (Nature - leaf.fill)"),
            icon: "leaf",
            systemCategories: ["nature"],
            excludedSymbols: ["leaf.fill"] // Exclude specifically leaf.fill from nature
        ),
        CustomCategory(
            label: String(localized: "Empty Category (Test)"),
            icon: "circle.dashed",
            symbols: [],
            systemCategories: []
        )
    ]
    
    // Properties for layout adjustment per platform
    private func formatScaleMultiplier(_ scale: Int) -> String {
        let multiplier: Double
        if scale <= 5 {
            multiplier = 0.5 + Double(scale - 1) * 0.125
        } else {
            multiplier = 1.0 + Double(scale - 5) * 0.2
        }
        return String(format: "%.2fx", multiplier)
    }

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
            #if !os(tvOS) && !os(watchOS)
            .adaptiveSafeAreaBar(edge: .bottom) {
                testPickerButton
            }
            #endif
        }
        #if os(macOS)
        .frame(width: 450, height: 500)
        #elseif os(visionOS)
        .frame(width: 600, height: 800)
        #endif
    }
    
    @ViewBuilder
    private var testPickerButtonLabel: some View {
        HStack(spacing: selectedIconSpacing) {
            if let icon = selectedIcon {
                Image(systemName: icon, variableValue: variableValue)
                    .font(.headline)
                    .symbolRenderingMode(renderingModeOption.mode)
                    .adaptiveSymbolColorRenderingMode(isGradient)
                    .foregroundStyle(
                        usePrimaryColor ? primaryColor : .primary,
                        useSecondaryColor ? secondaryColor : (usePrimaryColor ? primaryColor : .primary),
                        useTertiaryColor ? tertiaryColor : (usePrimaryColor ? primaryColor : .primary)
                    )
                    #if os(watchOS)
                    .frame(width: 32, height: 32)
                    #else
                    .frame(width: 44, height: 44)
                    .padding(.leading, 20)
                    #endif
                
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
        #if os(watchOS)
        .padding(.vertical, 0)
        #else
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func watchOSSheetPickerInstance() -> some View {
        SFSymbolPicker(
            isPresented: $isSheetPresented,
            selection: $selectedIcon,
            showAs: .sheet,
            controlBarPosition: controlBarPosition,
            showSearchBar: showSearchBar && searchBarStyle == .custom,
            searchText: $searchTextSheet,
            showCategoryPicker: showCategoryPicker,
            showCategorySectionLabel: showCategorySectionLabel,
            categoryLabelVisibility: categoryLabelVisibility,
            categoryLabelStyle: categoryLabelStyle,
            customCategories: demoCustomCategories,
            showIconName: showIconName,
            excludeRestricted: excludeRestricted,
            iconScale: iconScale,
            iconSpacing: iconSpacing,
            showRecents: showRecents,
            maxRecents: maxRecents,
            renderingMode: renderingModeOption.mode,
            isGradient: isGradient,
            primaryColor: usePrimaryColor ? primaryColor : .primary,
            secondaryColor: useSecondaryColor ? secondaryColor : nil,
            tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
            variableValue: $variableValue
        )
        .conditionalSearchable(show: showSearchBar && searchBarStyle == .searchable, text: $searchTextSheet, isSheet: pickerMode == .sheet)
    }
    
    @ViewBuilder
    private var testPickerButton: some View {
        #if os(tvOS)
        NavigationLink {
            SFSymbolPicker(
                isPresented: .constant(true),
                selection: $selectedIcon,
                showAs: .popover,
                controlBarPosition: controlBarPosition,
                showSearchBar: showSearchBar && searchBarStyle == .custom,
                searchText: $searchTextSheet,
                showCategoryPicker: showCategoryPicker,
                showCategorySectionLabel: showCategorySectionLabel,
                categoryLabelVisibility: categoryLabelVisibility,
                categoryLabelStyle: categoryLabelStyle,
                customCategories: demoCustomCategories,
                showIconName: showIconName,
                excludeRestricted: excludeRestricted,
                iconScale: iconScale,
                iconSpacing: iconSpacing,
                showRecents: showRecents,
                maxRecents: maxRecents,
                renderingMode: renderingModeOption.mode,
                isGradient: isGradient,
                primaryColor: usePrimaryColor ? primaryColor : .primary,
                secondaryColor: useSecondaryColor ? secondaryColor : nil,
                tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                variableValue: $variableValue
            )
            .conditionalSearchable(show: showSearchBar && searchBarStyle == .searchable, text: $searchTextSheet, isSheet: false)
        } label: {
            testPickerButtonLabel
        }
        #elseif os(watchOS)
        Group {
            if pickerMode == .sheet {
                Button {
                    isSheetPresented = true
                } label: {
                    testPickerButtonLabel
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isSheetPresented) {
                    NavigationStack {
                        watchOSSheetPickerInstance()
                    }
                }
            } else {
                NavigationLink {
                    watchOSSheetPickerInstance()
                } label: {
                    testPickerButtonLabel
                }
            }
        }
        #else
        Button {
            if pickerMode == .sheet {
                isSheetPresented = true
            } else {
                isPopoverPresented = true
            }
        } label: {
            HStack(spacing: 8) {
                if let icon = selectedIcon {
                    Image(systemName: icon, variableValue: variableValue)
                        .font(.title2)
                        .symbolRenderingMode(renderingModeOption.mode)
                        .adaptiveSymbolColorRenderingMode(isGradient)
                        .foregroundStyle(
                            usePrimaryColor ? primaryColor : .primary,
                            useSecondaryColor ? secondaryColor : (usePrimaryColor ? primaryColor : .primary),
                            useTertiaryColor ? tertiaryColor : (usePrimaryColor ? primaryColor : .primary)
                        )
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Selected Icon")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(icon)
                            .font(.callout.monospaced())
                    }
                } else {
                    Label("Select an Icon", systemImage: "plus.circle")
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #elseif os(visionOS)
            .background(.regularMaterial)
            #else
            .background(Color(uiColor: .systemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(16)
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
                    searchText: $searchTextSheet,
                    showCategoryPicker: showCategoryPicker,
                    showCategorySectionLabel: showCategorySectionLabel,
                    categoryLabelVisibility: categoryLabelVisibility,
                    categoryLabelStyle: categoryLabelStyle,
                    customCategories: demoCustomCategories,
                    showIconName: showIconName,
                    excludeRestricted: excludeRestricted,
                    iconScale: iconScale,
                    iconSpacing: iconSpacing,
                    showRecents: showRecents,
                    maxRecents: maxRecents,
                    renderingMode: renderingModeOption.mode,
                    isGradient: isGradient,
                    primaryColor: usePrimaryColor ? primaryColor : .primary,
                    secondaryColor: useSecondaryColor ? secondaryColor : nil,
                    tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                    variableValue: $variableValue
                )
            }
            .conditionalSearchable(show: showSearchBar && searchBarStyle == .searchable, text: $searchTextSheet, isSheet: true)
            #if os(macOS)
            .frame(width: 600, height: 500)
            #endif
        }
        .popover(isPresented: $isPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            SFSymbolPicker(
                isPresented: $isPopoverPresented,
                selection: $selectedIcon,
                showAs: .popover,
                controlBarPosition: controlBarPosition,
                showSearchBar: showSearchBar && searchBarStyle == .custom,
                searchText: $searchTextPopover,
                showCategoryPicker: showCategoryPicker,
                showCategorySectionLabel: showCategorySectionLabel,
                categoryLabelVisibility: categoryLabelVisibility,
                categoryLabelStyle: categoryLabelStyle,
                customCategories: demoCustomCategories,
                showIconName: showIconName,
                excludeRestricted: excludeRestricted,
                iconScale: iconScale,
                iconSpacing: iconSpacing,
                showRecents: showRecents,
                maxRecents: maxRecents,
                renderingMode: renderingModeOption.mode,
                isGradient: isGradient,
                primaryColor: usePrimaryColor ? primaryColor : .primary,
                secondaryColor: useSecondaryColor ? secondaryColor : nil,
                tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                variableValue: $variableValue
            )
            #if os(macOS)
            .frame(width: 360, height: 500)
            #elseif os(visionOS)
            .frame(width: 440, height: 540)
            #elseif os(iOS)
            .frame(width: horizontalSizeClass == .regular ? 360 : nil)
            .frame(maxHeight: horizontalSizeClass == .regular ? 500 : nil)
            #endif
        }
        #endif
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        #if os(tvOS) || os(watchOS)
        Section {
            testPickerButton
        } header: {
            Text("Picker Instance")
        }
        #endif
        
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
                    #if os(watchOS) || os(tvOS)
                    Text("Navigation Link").tag(SFSymbolPickerDisplayMode.popover)
                    #else
                    Text("Popover").tag(SFSymbolPickerDisplayMode.popover)
                    #endif
                } label: {
                    Text("Display Mode")
                }
                #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                .labelsHidden()
                .adaptiveButtonSizingFlexible()
            }
            
            #if !os(tvOS) && !os(watchOS)
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
                    #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                    #endif
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
                    #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                    #endif
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
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
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
                }
                
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
                    #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                    #endif
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
                        #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                    #endif
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
                    #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                    #endif
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
                        #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                    #endif
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
            
            #if !os(tvOS) && !os(watchOS)
            Stepper(value: $iconScale, in: 1...10) {
                HStack {
                    Text("Icon Scale: \(formatScaleMultiplier(iconScale))")
                    Spacer()
                    Text("\(iconScale)")
                        .foregroundStyle(.secondary)
                }
            }
            Stepper(value: $iconSpacing, in: 1...10) {
                HStack {
                    Text("Icon Spacing: \(formatScaleMultiplier(iconSpacing))")
                    Spacer()
                    Text("\(iconSpacing)")
                        .foregroundStyle(.secondary)
                }
            }
            #elseif os(watchOS)
            VStack(alignment: .leading, spacing: 4) {
                Text("Icon Scale")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper(value: $iconScale, in: 1...10) {
                    Text("\(iconScale)")
                }
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Icon Spacing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper(value: $iconSpacing, in: 1...10) {
                    Text("\(iconSpacing)")
                }
            }
            .padding(.vertical, 4)
            #else
            Picker(selection: $iconScale) {
                ForEach(1...10, id: \.self) { val in
                    Text("\(val) (\(formatScaleMultiplier(val)))").tag(val)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Icon Scale")
                    Text("Change the display size of icons in the grid.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            Picker(selection: $iconSpacing) {
                ForEach(1...10, id: \.self) { val in
                    Text("\(val) (\(formatScaleMultiplier(val)))").tag(val)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Icon Spacing")
                    Text("Change the spacing around icons.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            #endif
            
            Toggle("Show Recents", isOn: $showRecents)
                #if os(tvOS)
                .padding(.vertical, 8)
                #endif
            
            if showRecents {
                #if !os(tvOS) && !os(watchOS)
                Stepper(value: $maxRecents, in: 1...100) {
                    HStack {
                        Text("Max Recents")
                        Spacer()
                        Text("\(maxRecents)")
                            .foregroundStyle(.secondary)
                    }
                }
                #elseif os(watchOS)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Recents")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper(value: $maxRecents, in: 1...100) {
                        Text("\(maxRecents)")
                    }
                }
                .padding(.vertical, 4)
                #else
                Picker(selection: $maxRecents) {
                    ForEach(Array(stride(from: 1, through: 100, by: 1)), id: \.self) { val in
                        Text("\(val)").tag(val)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max Recents")
                        Text("Change the maximum number of recently used icons.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                #endif
            }
            
            Button(role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "design.taikun.UniversalSFSymbolsPicker.recents")
            } label: {
                Text("Reset Recently Used Icons")
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
                Picker("Rendering Mode", selection: $renderingModeOption) {
                    ForEach(RenderingModeOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .labelsHidden()
                #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
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
                #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
                .labelsHidden()
                .adaptiveButtonSizingFlexible()
            }
            #endif
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                Toggle(isOn: $isGradient) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gradient")
                        Text("Enable gradient rendering for symbols (iOS 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+, visionOS 26.0+).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                #if os(tvOS)
                .padding(.vertical, 8)
                #endif
            }
            
            Toggle(isOn: $usePrimaryColor) {
                Text("Primary Color")
            }
            if usePrimaryColor {
                #if !os(tvOS) && !os(watchOS)
                ColorPicker("Select Primary Color", selection: $primaryColor)
                #endif
            }
            
            Toggle(isOn: $useSecondaryColor) {
                Text("Secondary Color")
            }
            if useSecondaryColor {
                #if !os(tvOS) && !os(watchOS)
                ColorPicker("Select Secondary Color", selection: $secondaryColor)
                #endif
            }
            
            Toggle(isOn: $useTertiaryColor) {
                Text("Tertiary Color")
            }
            if useTertiaryColor {
                #if !os(tvOS) && !os(watchOS)
                ColorPicker("Select Tertiary Color", selection: $tertiaryColor)
                #endif
            }
        } header: {
            Text("Dynamic Rendering Demo")
        }
        
        #if !os(tvOS) && !os(watchOS)
        Section {
            #if os(macOS)
            Button(action: {
                openWindow(id: "BuildMode")
            }) {
                Text("Open Build Mode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            #elseif os(visionOS)
            Button(action: {
                isVisionOSBuildModePresented = true
            }) {
                Text("Open Build Mode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .sheet(isPresented: $isVisionOSBuildModePresented) {
                NavigationStack {
                    BuildModeView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    isVisionOSBuildModePresented = false
                                }
                            }
                        }
                }
                .frame(width: 1200, height: 800)
            }
            #else
            NavigationLink(destination: BuildModeView()) {
                Text("Open Build Mode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            #endif
        }
        #endif
    }
}


#Preview("Default View") {
    ContentView()
}

#Preview("Sheet Presented") {
    ContentView(isSheetPresented: true)
}

// MARK: - Helper Extension

extension View {
    @ViewBuilder
    func conditionalSearchable(show: Bool, text: Binding<String>, isSheet: Bool) -> some View {
        let promptText = isSheet ? String(localized: "Search icons in sheet…") : String(localized: "Search Icons…")
        if show {
            #if os(watchOS)
            self.searchable(text: text, placement: .toolbar, prompt: Text(promptText))
            #else
            self.searchable(text: text, prompt: Text(promptText))
            #endif
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
    
    @ViewBuilder
    func adaptiveSymbolColorRenderingMode(_ isGradient: Bool) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            if isGradient {
                self.symbolColorRenderingMode(.gradient)
            } else {
                self.symbolColorRenderingMode(.flat)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func adaptiveSafeAreaBar<Content: View>(edge: VerticalEdge, @ViewBuilder content: @escaping () -> Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            self.safeAreaBar(edge: edge, content: content)
        } else {
            self.safeAreaInset(edge: edge, content: content)
        }
    }
}
