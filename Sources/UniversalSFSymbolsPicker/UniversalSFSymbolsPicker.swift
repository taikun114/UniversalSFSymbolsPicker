import SwiftUI

/// The display mode for the SF Symbols picker.
public enum SFSymbolPickerDisplayMode: Sendable {
    case sheet
    case popover
}

/// The position of the control bar (search bar and category picker).
public enum SFSymbolPickerControlBarPosition: Sendable {
    case top
    case bottom
}

/// The mode for displaying the category picker label.
public enum SFSymbolPickerCategoryLabelVisibility: Sendable {
    case `default`
    case visible
    case hidden
}

/// The style for the category picker label text.
public enum SFSymbolPickerCategoryLabelStyle: Sendable {
    case both      // "Category: Name"
    case titleOnly // "Category"
    case nameOnly  // "Name"
}

public struct SFSymbolPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @Binding var isPresented: Bool
    @Binding var selection: String?
    let showAs: SFSymbolPickerDisplayMode
    let controlBarPosition: SFSymbolPickerControlBarPosition
    let showSearchBar: Bool
    
    let prompt: String
    let showCategoryPicker: Bool
    let showCategorySectionLabel: Bool
    let categoryLabelVisibility: SFSymbolPickerCategoryLabelVisibility
    let categoryLabelStyle: SFSymbolPickerCategoryLabelStyle
    let showIconName: Bool
    let defaultCategory: String
    let includedCategories: [String]?
    let excludedCategories: [String]?
    let customCategories: [CustomCategory]
    let excludeRestricted: Bool
    let sfSymbolsVersion: Double?
    
    // Rendering & Style
    let renderingMode: SymbolRenderingMode
    let primaryColor: Color
    let secondaryColor: Color?
    let tertiaryColor: Color?
    @Binding var variableValue: Double?
    @Binding var searchText: String
    
    // Computed Properties for Layout
    private var effectiveControlBarPosition: SFSymbolPickerControlBarPosition {
        #if os(tvOS)
        return .top
        #else
        return controlBarPosition
        #endif
    }
    
    // Internal State
    @State private var selectedCategoryID: String
    @State private var temporarySelection: String?
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTapName: String? = nil
    
    // Pagination State
    @State private var allFilteredSymbols: [String] = []
    @State private var displayedSymbols: [String] = [] // Flattened list of displayed symbols
    private let pageSize = 100
    
    private let service = SFSymbolService.shared
    
    /// The standard height for bars and buttons, adjusted for each platform
    private var controlHeight: CGFloat {
        #if os(macOS)
        return 32
        #else
        return 40
        #endif
    }
    
    /// Updates the list of symbols based on current filters and resets pagination
    private func updateFilteredSymbols() {
        let rawSymbols = service.symbols(
            for: selectedCategoryID,
            customCategories: customCategories,
            includedIDs: includedCategories,
            excludedIDs: excludedCategories,
            excludeRestricted: excludeRestricted,
            limitVersion: sfSymbolsVersion
        )
        // Execute search
        let searched = service.search(query: searchText, in: rawSymbols)
        
        // Resolve effective names to ensure version compatibility.
        // This processes all symbols (system-defined, custom, and search results) through the version filter.
        // It selects the most appropriate alias for the current OS, or falls back to a placeholder.
        allFilteredSymbols = searched.map { service.effectiveName(for: $0, limitVersion: sfSymbolsVersion) ?? "questionmark.square.dashed" }
        
        // Set the first page
        displayedSymbols = Array(allFilteredSymbols.prefix(pageSize))
    }
    
    /// Loads the next page of symbols
    private func loadNextPage() {
        let currentCount = displayedSymbols.count
        guard currentCount < allFilteredSymbols.count else { return }
        
        let nextCount = min(currentCount + pageSize, allFilteredSymbols.count)
        let nextPage = allFilteredSymbols[currentCount..<nextCount]
        displayedSymbols.append(contentsOf: nextPage)
    }
    
    /// Helper to dismiss the picker reliably across platforms
    private func close(save: Bool = false) {
        if save, let temp = temporarySelection {
            selection = temp
        }
        
        #if os(macOS)
        isPresented = false
        dismiss()
        presentationMode.wrappedValue.dismiss()
        #elseif !os(tvOS)
        isPresented = false
        dismiss()
        presentationMode.wrappedValue.dismiss()
        #endif
    }
    
    /// Returns the icon for the currently selected category
    private var currentCategoryIcon: String {
        if selectedCategoryID == "all" {
            return "square.grid.2x2"
        }
        let rawIcon: String
        if let custom = customCategories.first(where: { $0.id.uuidString == selectedCategoryID }) {
            rawIcon = custom.icon
        } else {
            rawIcon = service.systemCategories.first(where: { $0.id == selectedCategoryID })?.icon ?? "square.grid.2x2"
        }
        return service.effectiveName(for: rawIcon, limitVersion: sfSymbolsVersion) ?? rawIcon
    }
    
    /// Returns the label for the currently selected category
    private var currentCategoryLabel: String {
        if selectedCategoryID == "all" {
            return String(localized: "All", bundle: .module)
        }
        if let custom = customCategories.first(where: { $0.id.uuidString == selectedCategoryID }) {
            return custom.label
        }
        if let system = service.systemCategories.first(where: { $0.id == selectedCategoryID }) {
            return String(localized: String.LocalizationValue(system.label), bundle: .module)
        }
        return String(localized: "All", bundle: .module)
    }
    
    /// Returns the text to display in the category picker label based on current style
    private var categoryDisplayText: String {
        switch categoryLabelStyle {
        case .both:
            return String(localized: "Category: \(currentCategoryLabel)", bundle: .module)
        case .titleOnly:
            return String(localized: "Category", bundle: .module)
        case .nameOnly:
            return currentCategoryLabel
        }
    }
    
    /// Determines whether to show the category label based on settings and context
    private var shouldShowCategoryLabel: Bool {
        switch categoryLabelVisibility {
        case .visible:
            return true
        case .hidden:
            return false
        case .default:
            #if os(macOS)
            if showAs == .sheet {
                return true
            } else {
                // Popover: Show only if search bar is hidden
                return !showSearchBar
            }
            #elseif os(iOS)
            if showAs == .sheet {
                // Sheet: Show only in regular layout
                return horizontalSizeClass != .compact
            } else {
                // Popover: Show only if search bar is hidden
                return !showSearchBar
            }
            #elseif os(visionOS)
            if showAs == .sheet {
                return false
            } else {
                // Popover: Show only if search bar is hidden
                return !showSearchBar
            }
            #else
            // tvOS, watchOS, etc.
            return true
            #endif
        }
    }
    
    public init(
        isPresented: Binding<Bool>,
        selection: Binding<String?>,
        showAs: SFSymbolPickerDisplayMode,
        controlBarPosition: SFSymbolPickerControlBarPosition = .bottom,
        showSearchBar: Bool = true, // Only effective in Popover mode
        prompt: String? = nil,
        showCategoryPicker: Bool = true,
        showCategorySectionLabel: Bool = true,
        categoryLabelVisibility: SFSymbolPickerCategoryLabelVisibility = .default,
        categoryLabelStyle: SFSymbolPickerCategoryLabelStyle = .both,
        showIconName: Bool = true,
        defaultCategory: String = "all",
        includedCategories: [String]? = nil,
        excludedCategories: [String]? = nil,
        customCategories: [CustomCategory] = [],
        excludeRestricted: Bool = false,
        sfSymbolsVersion: Double? = nil,
        renderingMode: SymbolRenderingMode = .monochrome,
        primaryColor: Color = .primary,
        secondaryColor: Color? = nil,
        tertiaryColor: Color? = nil,
        variableValue: Binding<Double?> = .constant(nil),
        searchText: Binding<String> = .constant("")
    ) {
        self._isPresented = isPresented
        self._selection = selection
        self.showAs = showAs
        self.controlBarPosition = controlBarPosition
        self.showSearchBar = showSearchBar
        self.prompt = prompt ?? String(localized: "Search Icons...", bundle: .module)
        self.showCategoryPicker = showCategoryPicker
        self.showCategorySectionLabel = showCategorySectionLabel
        self.categoryLabelVisibility = categoryLabelVisibility
        self.categoryLabelStyle = categoryLabelStyle
        self.showIconName = showIconName
        self.defaultCategory = defaultCategory
        self.includedCategories = includedCategories
        self.excludedCategories = excludedCategories
        self.customCategories = customCategories
        self.excludeRestricted = excludeRestricted
        self.sfSymbolsVersion = sfSymbolsVersion
        self.renderingMode = renderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self._variableValue = variableValue
        self._searchText = searchText
        self._selectedCategoryID = State(initialValue: defaultCategory)
        self._temporarySelection = State(initialValue: selection.wrappedValue)
    }

    
    public var body: some View {
        Group {
            if showAs == .sheet {
                sheetView
            } else {
                popoverView
            }
        }
        .onDisappear {
            #if os(tvOS)
            // On tvOS, selection is confirmed when leaving screen as there is no explicit done button
            selection = temporarySelection
            #else
            // Confirmation on leaving for popover mode
            if showAs == .popover {
                selection = temporarySelection
            }
            #endif
        }
    }
    
    // MARK: - Sheet View
    
    private var sheetView: some View {
        VStack(spacing: 0) {
            #if os(tvOS)
            // On tvOS, place everything within ScrollView and let the OS handle focus control
            symbolGrid
            #else
            symbolGrid
                .adaptiveSoftEdge()
                .adaptiveSafeAreaBar(edge: .top) {
                    if (showSearchBar || showCategoryPicker) && effectiveControlBarPosition == .top {
                        searchBox
                    }
                }
                .adaptiveSafeAreaBar(edge: .bottom) {
                    #if os(macOS)
                    macOSBottomBar
                    #else
                    if (showSearchBar || showCategoryPicker) && effectiveControlBarPosition == .bottom {
                        searchBox
                    }
                    #endif
                }
            #endif
        }
        #if !os(macOS) && !os(tvOS)
        .navigationTitle(String(localized: "Select an Icon", bundle: .module))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    Button(role: .cancel) {
                        close(save: false)
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel(String(localized: "Cancel", bundle: .module))
                    .help(String(localized: "Cancel selection", bundle: .module))
                } else {
                    Button(role: .cancel) {
                        close(save: false)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel(String(localized: "Cancel", bundle: .module))
                    .help(String(localized: "Cancel selection", bundle: .module))
                }
            }
            
            if showCategoryPicker {
                ToolbarItem(placement: .primaryAction) {
                    sheetCategoryPicker
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                doneButton
                    .keyboardShortcut(.defaultAction)
            }
        }
        #endif
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    // MARK: - Popover View
    
    private var popoverView: some View {
        VStack(spacing: 0) {
            symbolGrid
                #if !os(tvOS)
                .adaptiveSafeAreaBar(edge: effectiveControlBarPosition == .top ? .top : .bottom) {
                    if showSearchBar || showCategoryPicker {
                        searchBox
                    }
                }
                #endif
        }
        #if os(macOS)
        .frame(width: 360, height: 500) // Fixed size for macOS popover
        #elseif os(visionOS)
        .frame(width: 440, height: 540) // Fixed size for visionOS popover
        #else
        .frame(minWidth: 320, minHeight: 400)
        #endif
    }

    
    // MARK: - Components
    
    private var symbolGrid: some View {
        #if os(tvOS)
        let minWidth: CGFloat = 160
        let spacing: CGFloat = 80
        #else
        let minWidth: CGFloat = 65
        let spacing: CGFloat = 20
        #endif
        
        let columns = [GridItem(.adaptive(minimum: minWidth))]
        
        return ScrollViewReader { proxy in
            ScrollView {
                #if os(tvOS)
                // tvOS specific: Always displayed at top
                if showSearchBar {
                    searchBox
                        .padding(.top, 80)
                        .padding(.bottom, 40)
                        .padding(.horizontal, spacing)
                } else if showCategoryPicker {
                    HStack {
                        Spacer()
                        sheetCategoryPicker
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        Spacer()
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 40)
                }
                #endif
                
                // Anchor to scroll to top
                Color.clear
                    .frame(height: 0)
                    .id("top_anchor")
                
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(displayedSymbols, id: \.self) { name in
                        symbolButton(for: name)
                            .onAppear {
                                if name == displayedSymbols.last {
                                    loadNextPage()
                                }
                            }
                    }
                }
                .padding(.horizontal, spacing)
                #if os(tvOS)
                .padding(.bottom, 200) // Ensure enough bottom padding for tvOS
                #else
                .padding(.top, ((showSearchBar || showCategoryPicker) && effectiveControlBarPosition == .top) ? 0 : spacing)
                .padding(.bottom, (showAs == .sheet && effectiveControlBarPosition == .bottom) || showAs == .sheet ? 0 : spacing)
                #endif
            }
            .onChange(of: selectedCategoryID) { _, _ in
                updateFilteredSymbols()
                #if !os(tvOS)
                // Scroll to top on category change (except tvOS)
                proxy.scrollTo("top_anchor", anchor: .top)
                #endif
            }
            .onChange(of: searchText) { _, _ in
                updateFilteredSymbols()
                #if !os(tvOS)
                // Scroll to top on search query change (except tvOS)
                proxy.scrollTo("top_anchor", anchor: .top)
                #endif
            }
            .onAppear {
                if displayedSymbols.isEmpty {
                    updateFilteredSymbols()
                }
            }
        }
    }
    
    private func symbolButton(for name: String) -> some View {
        let isSelected = (selection == name)
        let isProvisionallySelected = (temporarySelection == name)
        
        #if os(tvOS)
        let iconSize: CGFloat = 60 // Slightly larger for tvOS
        let nameHeight: CGFloat = 64
        #else
        let iconSize: CGFloat = 28
        let nameHeight: CGFloat = 32
        #endif
        
        let content = VStack(spacing: 8) {
            Image(systemName: name, variableValue: variableValue)
                .font(.system(size: iconSize))
                .symbolRenderingMode(renderingMode)
                #if !os(tvOS)
                .foregroundStyle(
                    isProvisionallySelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(primaryColor)
                )
                #endif

            if showIconName {
                let displayLabel = name.replacingOccurrences(of: ".", with: ".\u{200B}")
                Text(displayLabel)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    #if !os(tvOS)
                    .foregroundStyle(
                        isProvisionallySelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.secondary)
                    )
                    #endif
                    .frame(height: nameHeight, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .contentShape(Rectangle())
        
        return Button {
            #if os(tvOS)
            // Update selection without closing automatically on tvOS
            temporarySelection = name
            selection = name
            #else
            let now = Date()
            let diff = now.timeIntervalSince(lastTapTime)
            
            // 1. Immediately update selection state
            temporarySelection = name
            
            // 2. Double-tap detection (same icon within 0.5s)
            if name == lastTapName && diff < 0.5 {
                close(save: true)
            }
            
            // 3. Save current tap info
            lastTapTime = now
            lastTapName = name
            #endif
        } label: {
            content
                .background {
                    #if os(tvOS)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(primaryColor, lineWidth: 6)
                            .padding(-12)
                    }
                    #else
                    if isProvisionallySelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                    } else if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                    #endif
                }
        }
        .buttonStyle(.plain)
        .help(name)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityHint(String(localized: "Double-tap or double-click to select", bundle: .module))
    }
    
    private var sheetCategoryPicker: some View {
        Menu {
            categoryMenuItems
        } label: {
            HStack(spacing: 8) {
                Image(systemName: currentCategoryIcon)
                if shouldShowCategoryLabel {
                    Text(categoryDisplayText)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityLabel(String(localized: "Category Button", bundle: .module))
        .accessibilityHint(String(localized: "Changes the icon category. Current category: \(currentCategoryLabel)", bundle: .module))
        .help(String(localized: "Changes the icon category. Current category: \(currentCategoryLabel)", bundle: .module))
    }
    
    private var popoverCategoryPicker: some View {
        Menu {
            categoryMenuItems
        } label: {
            Group {
                if !shouldShowCategoryLabel {
                    Image(systemName: currentCategoryIcon)
                        .frame(width: controlHeight, height: controlHeight)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: currentCategoryIcon)
                        Text(categoryDisplayText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, controlHeight * 0.4)
                    .frame(height: controlHeight)
                }
            }
            .foregroundStyle(.primary)
            .background {
                #if os(visionOS)
                Capsule().fill(.regularMaterial)
                #else
                if colorSchemeContrast == .increased {
                    #if os(macOS)
                    Color(NSColor.controlBackgroundColor)
                        .clipShape(Capsule())
                    #elseif os(tvOS)
                    Color.black.opacity(0.4)
                        .clipShape(Capsule())
                    #else
                    Color(UIColor.secondarySystemBackground)
                        .clipShape(Capsule())
                    #endif
                } else {
                    if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                        Color.clear
                            .adaptiveGlassEffectStyle(.clearInteractive, in: Capsule())
                    } else {
                        #if os(macOS)
                        VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                            .clipShape(Capsule())
                        #else
                        Capsule().fill(.thinMaterial)
                        #endif
                    }
                }
                #endif
            }
            .overlay(
                Capsule()
                    .stroke(colorSchemeContrast == .increased ? Color.primary : Color.gray.opacity(0.3), lineWidth: colorSchemeContrast == .increased ? 2 : 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Category Button", bundle: .module))
        .accessibilityHint(String(localized: "Changes the icon category. Current category: \(currentCategoryLabel)", bundle: .module))
        .help(String(localized: "Changes the icon category. Current category: \(currentCategoryLabel)", bundle: .module))
    }
    
    #if os(macOS)
    private var macOSBottomBar: some View {
        VStack(spacing: 0) {
            if (showSearchBar || showCategoryPicker) && effectiveControlBarPosition == .bottom {
                searchBox
            }
            
            HStack {
                Button(role: .cancel) {
                    close(save: false)
                } label: {
                    Label(String(localized: "Cancel", bundle: .module), systemImage: "xmark")
                }
                #if !os(tvOS)
                .keyboardShortcut(.cancelAction)
                #endif
                .controlSize(.large)
                #if os(macOS)
                .adaptiveGlassButtonStyle()
                #endif
                .accessibilityLabel(String(localized: "Cancel", bundle: .module))
                .help(String(localized: "Cancel selection", bundle: .module))
                
                Spacer()
                
                if showCategoryPicker {
                    sheetCategoryPicker
                        .controlSize(.large)
                        #if os(macOS)
                        .adaptiveGlassEffectStyle(colorSchemeContrast == .increased ? .regular : .clearInteractive)
                        #endif
                }
                
                Button {
                    close(save: true)
                } label: {
                    Label(String(localized: "Done", bundle: .module), systemImage: "checkmark")
                }
                #if !os(tvOS)
                .keyboardShortcut(.defaultAction)
                #endif
                .controlSize(.large)
                #if os(macOS)
                .adaptiveGlassProminentButtonStyle()
                #endif
                .accessibilityLabel(String(localized: "Done", bundle: .module))
                .help(String(localized: "Confirm selection", bundle: .module))
            }
            .padding()
        }
        .background {
            if #available(macOS 26.0, *) {
                Color.clear
            } else {
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
            }
        }
    }
    #endif
    
    #if os(tvOS)
    private var tvOSControlBar: some View {
        VStack(spacing: 30) {
            sheetCategoryPicker
            
            if showSearchBar {
                searchBox
            }
        }
        .padding(.vertical, 40)
        .background(.regularMaterial)
    }
    #endif
    
    @ViewBuilder
    private var categoryMenuItems: some View {
        // 1. All Symbols Picker
        allSymbolsContent
        
        // 2. System Categories Picker
        systemCategoriesContent
        
        // 3. Custom Categories Picker
        if !customCategories.isEmpty {
            customCategoriesContent
        }
    }
    
    @ViewBuilder
    private var allSymbolsContent: some View {
        let allSymbolsTitle = String(localized: "All Symbols", bundle: .module)
        Picker(allSymbolsTitle, selection: $selectedCategoryID) {
            Label(
                String(localized: "All", bundle: .module),
                systemImage: "square.grid.2x2"
            ).tag("all")
        }
        .pickerStyle(.inline)
        .adaptiveLabelsVisibility(showCategorySectionLabel ? .visible : .hidden)
    }
    
    @ViewBuilder
    private var systemCategoriesContent: some View {
        let systemCategoriesTitle = String(localized: "System Categories", bundle: .module)
        Picker(systemCategoriesTitle, selection: $selectedCategoryID) {
            ForEach(service.systemCategories) { cat in
                if cat.id != "all" {
                    let iconName = service.effectiveName(for: cat.icon, limitVersion: sfSymbolsVersion) ?? "square.grid.2x2"
                    Label(
                        String(localized: String.LocalizationValue(cat.label), bundle: .module),
                        systemImage: iconName
                    ).tag(cat.id)
                }
            }
        }
        .pickerStyle(.inline)
        .adaptiveLabelsVisibility(showCategorySectionLabel ? .visible : .hidden)
    }
    
    @ViewBuilder
    private var customCategoriesContent: some View {
        let customCategoriesTitle = String(localized: "Custom Categories", bundle: .module)
        Picker(customCategoriesTitle, selection: $selectedCategoryID) {
            ForEach(customCategories) { cat in
                let iconName = service.effectiveName(for: cat.icon, limitVersion: sfSymbolsVersion) ?? "square.grid.2x2"
                Label(cat.label, systemImage: iconName).tag(cat.id.uuidString)
            }
        }
        .pickerStyle(.inline)
        .adaptiveLabelsVisibility(showCategorySectionLabel ? .visible : .hidden)
    }
    
    private var doneButton: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                Button(role: .confirm) {
                    close(save: true)
                }
            } else {
                Button {
                    close(save: true)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                }
            }
        }
        .accessibilityLabel(String(localized: "Done", bundle: .module))
        .help(String(localized: "Confirm selection", bundle: .module))
    }

    
    private var searchBox: some View {
        #if os(tvOS)
        // tvOS specific: Extremely simplified search and category bar
        HStack(spacing: 20) {
            // Search input area (Magnifying glass + Text field)
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                TextField(prompt, text: $searchText)
                    .font(.headline)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            
            // Category picker
            if showCategoryPicker {
                sheetCategoryPicker
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(height: 80)
            }
        }
        #else
        // Island configuration for iOS/macOS/visionOS
        HStack(spacing: 12) {
            if showSearchBar {
                ZStack {
                    #if os(visionOS)
                    Color.clear
                        .background(.regularMaterial, in: Capsule())
                    #else
                    if colorSchemeContrast == .increased {
                        #if os(macOS)
                        Color(NSColor.controlBackgroundColor)
                            .clipShape(Capsule())
                        #elseif os(tvOS)
                        Color.black.opacity(0.4)
                            .clipShape(Capsule())
                        #else
                        Color(UIColor.secondarySystemBackground)
                            .clipShape(Capsule())
                        #endif
                    } else {
                        Color.clear
                            .adaptiveGlassEffectStyle(.clear, in: Capsule())
                    }
                    #endif
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(searchIconColor)
                            .font(.body.weight(.semibold))
                            .accessibilityHidden(true)
                        
                        TextField(prompt, text: $searchText)
                            .textFieldStyle(.plain)
                            .background(Color.clear)
                            .accessibilityLabel(prompt)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(searchIconColor)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Clear search", bundle: .module))
                            .help(String(localized: "Clear search", bundle: .module))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, controlHeight == 32 ? 6 : 10)
                }
                .frame(height: controlHeight)
                .overlay(
                    Capsule()
                        .stroke(colorSchemeContrast == .increased ? Color.primary : Color.gray.opacity(0.3), lineWidth: colorSchemeContrast == .increased ? 2 : 1)
                )
            }

            if showCategoryPicker && showAs == .popover {
                popoverCategoryPicker
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, (showAs == .sheet && effectiveControlBarPosition == .bottom && osIsMacOS) ? 0 : 16)
        .fixedSize(horizontal: false, vertical: true)
        #endif
    }
    
    /// Helper to identify macOS at runtime within views
    private var osIsMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    private var searchIconColor: Color {
        #if os(visionOS)
        return colorSchemeContrast == .increased ? .primary : .secondary
        #else
        return .secondary
        #endif
    }
}

// MARK: - Extension for Future APIs

public enum AdaptiveGlassStyle: Sendable {
    case regular
    case interactive
    case clear
    case clearInteractive
}

public enum AdaptiveLabelsVisibility: Sendable {
    case visible
    case hidden
    case automatic
}

private extension View {
    @ViewBuilder
    func adaptiveLabelsVisibility(_ visibility: AdaptiveLabelsVisibility) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            switch visibility {
            case .visible:
                self.labelsVisibility(.visible)
            case .hidden:
                self.labelsVisibility(.hidden)
            case .automatic:
                self.labelsVisibility(.automatic)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func adaptiveSafeAreaBar<Content: View>(edge: VerticalEdge, @ViewBuilder content: @escaping () -> Content) -> some View {
        #if canImport(SwiftUI)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            self.safeAreaBar(edge: edge, content: content)
        } else {
            self.safeAreaInset(edge: edge == .top ? .top : .bottom, content: content)
        }
        #else
        self.safeAreaInset(edge: edge == .top ? .top : .bottom, content: content)
        #endif
    }
    
    @ViewBuilder
    func adaptiveLiquidGlass<S: Shape>(in shape: S) -> some View {
        #if os(iOS) || os(macOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
        #else
        self.background(.ultraThinMaterial, in: shape)
        #endif
    }
    
    @ViewBuilder
    func adaptiveGlassEffectStyle(_ style: AdaptiveGlassStyle = .regular, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            #if !os(visionOS)
            let glass: Glass = {
                switch style {
                case .regular: return .regular
                case .interactive: return .regular.interactive()
                case .clear: return .clear
                case .clearInteractive: return .clear.interactive()
                }
            }()
            let tintedGlass = tint != nil ? glass.tint(tint!) : glass
            self.glassEffect(tintedGlass)
            #else
            self
            #endif
        } else {
            self
        }
    }
    
    @ViewBuilder
    func adaptiveGlassEffectStyle<S: Shape>(_ style: AdaptiveGlassStyle = .regular, tint: Color? = nil, in shape: S) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            #if !os(visionOS)
            let glass: Glass = {
                switch style {
                case .regular: return .regular
                case .interactive: return .regular.interactive()
                case .clear: return .clear
                case .clearInteractive: return .clear.interactive()
                }
            }()
            let tintedGlass = tint != nil ? glass.tint(tint!) : glass
            self.glassEffect(tintedGlass, in: shape)
            #else
            self.background(.ultraThinMaterial, in: shape)
            #endif
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
    
    @ViewBuilder
    func adaptiveGlassButtonStyle() -> some View {
        #if !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self
        }
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func adaptiveGlassProminentButtonStyle() -> some View {
        #if !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self
        }
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func adaptiveSoftEdge() -> some View {
        #if os(macOS) || os(iOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// MARK: - Previews

#Preview("Sheet (No Search)") {
    NavigationStack {
        SFSymbolPicker(isPresented: .constant(true), selection: .constant("star.fill"), showAs: .sheet, showSearchBar: false, showIconName: true, searchText: .constant(""))
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Sheet (Search Top)") {
    NavigationStack {
        SFSymbolPicker(isPresented: .constant(true), selection: .constant("star.fill"), showAs: .sheet, controlBarPosition: .top, showSearchBar: true, showIconName: true, searchText: .constant(""))
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Sheet (Search Bottom)") {
    NavigationStack {
        SFSymbolPicker(isPresented: .constant(true), selection: .constant("star.fill"), showAs: .sheet, controlBarPosition: .bottom, showSearchBar: true, showIconName: true, searchText: .constant(""))
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Popover Mode (Bottom)") {
    SFSymbolPicker(isPresented: .constant(true), selection: .constant("heart.fill"), showAs: .popover, controlBarPosition: .bottom, showIconName: true, searchText: .constant(""))
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}

#Preview("Popover Mode (Top)") {
    SFSymbolPicker(isPresented: .constant(true), selection: .constant("gearshape.fill"), showAs: .popover, controlBarPosition: .top, showIconName: true, searchText: .constant(""))
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}
