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
    
    @Binding var isPresented: Bool
    @Binding var selection: String?
    let showAs: SFSymbolPickerDisplayMode
    let controlBarPosition: SFSymbolPickerControlBarPosition
    let showSearchBar: Bool
    
    let prompt: String
    let showCategoryPicker: Bool
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
    private let service = SFSymbolService.shared
    
    /// The standard height for bars and buttons, adjusted for each platform
    private var controlHeight: CGFloat {
        #if os(macOS)
        return 32
        #else
        return 40
        #endif
    }
    
    /// Helper to dismiss the picker reliably across platforms
    private func close(save: Bool = false) {
        if save, let temp = temporarySelection {
            selection = temp
        }
        
        #if os(tvOS)
        // tvOS でも dismiss() を呼び出すことで、NavigationLink 等の多様な遷移に対応させる
        isPresented = false
        dismiss()
        #elseif os(macOS)
        isPresented = false
        dismiss()
        presentationMode.wrappedValue.dismiss()
        #else
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
        if let custom = customCategories.first(where: { $0.id.uuidString == selectedCategoryID }) {
            return custom.icon
        }
        return service.systemCategories.first(where: { $0.id == selectedCategoryID })?.icon ?? "square.grid.2x2"
    }
    
    /// Returns the label for the currently selected category
    private var currentCategoryLabel: String {
        if selectedCategoryID == "all" {
            return "All"
        }
        if let custom = customCategories.first(where: { $0.id.uuidString == selectedCategoryID }) {
            return custom.label
        }
        return service.systemCategories.first(where: { $0.id == selectedCategoryID })?.label ?? "All"
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
        prompt: String = "Search Icons...",
        showCategoryPicker: Bool = true,
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
        self.prompt = prompt
        self.showCategoryPicker = showCategoryPicker
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
    }
    
    // MARK: - Sheet View
    
    private var sheetView: some View {
        VStack(spacing: 0) {
            #if os(tvOS)
            // tvOS では ScrollView 内にすべてを配置し、フォーカス制御を OS に任せる
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
        .navigationTitle("Select an Icon")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    Button(role: .cancel) {
                        close(save: false)
                    }
                    .keyboardShortcut(.cancelAction)
                } else {
                    Button(role: .cancel) {
                        close(save: false)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .keyboardShortcut(.cancelAction)
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
        .frame(width: 360, height: 500) // macOS 専用の固定サイズ指定
        #elseif os(visionOS)
        .frame(width: 440, height: 540) // visionOS 専用の固定サイズ指定
        #else
        .frame(minWidth: 320, minHeight: 400)
        #endif
        .onDisappear {
            // ポップオーバーが閉じられた際に選択を確定
            selection = temporarySelection
        }
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
        let symbols = service.symbols(
            for: selectedCategoryID,
            customCategories: customCategories,
            includedIDs: includedCategories,
            excludedIDs: excludedCategories,
            excludeRestricted: excludeRestricted,
            limitVersion: sfSymbolsVersion
        )
        let filteredSymbols = service.search(query: searchText, in: symbols)
        
        return ScrollViewReader { proxy in
            ScrollView {
                #if os(tvOS)
                // tvOS 専用：常に上部に表示
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
                
                // 最上部へスクロールするためのアンカー
                Color.clear
                    .frame(height: 0)
                    .id("top_anchor")
                
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(filteredSymbols, id: \.self) { name in
                        symbolButton(for: name)
                    }
                }
                .padding(.horizontal, spacing)
                #if os(tvOS)
                .padding(.bottom, 200) // 下側のマージンをしっかり確保
                #else
                .padding(.top, ((showSearchBar || showCategoryPicker) && effectiveControlBarPosition == .top) ? 0 : spacing)
                .padding(.bottom, (showAs == .sheet && effectiveControlBarPosition == .bottom) || showAs == .sheet ? 0 : spacing)
                #endif
            }
            .onChange(of: selectedCategoryID) { _, _ in
                // カテゴリ変更時に最上部へスクロール
                withAnimation {
                    proxy.scrollTo("top_anchor", anchor: .top)
                }
            }
        }
    }
    
    private func symbolButton(for name: String) -> some View {
        let effectiveName = service.effectiveName(for: name) ?? name
        let isSelected = (temporarySelection == effectiveName) || (selection == effectiveName)
        
        #if os(tvOS)
        let iconSize: CGFloat = 60 // tvOS では少し大きく
        let nameHeight: CGFloat = 64
        #else
        let iconSize: CGFloat = 28
        let nameHeight: CGFloat = 32
        #endif
        
        let content = VStack(spacing: 8) {
            Image(systemName: effectiveName, variableValue: variableValue)
                .font(.system(size: iconSize))
                .symbolRenderingMode(isSelected ? .monochrome : renderingMode)
                .foregroundStyle(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(primaryColor))

            if showIconName {
                let displayLabel = effectiveName.replacingOccurrences(of: ".", with: ".\u{200B}")
                Text(displayLabel)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(isSelected ? Color.white : .secondary)
                    .frame(height: nameHeight, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        
        #if os(tvOS)
        return Button {
            temporarySelection = effectiveName
            close(save: true)
        } label: {
            content
        }
        .buttonStyle(.plain) // tvOS のフォーカスエフェクトを活かす
        #else
        return content
            .onTapGesture {
                let now = Date()
                let diff = now.timeIntervalSince(lastTapTime)
                
                // 1. 即座に選択状態を更新
                temporarySelection = effectiveName
                
                // 2. ダブルタップ判定 (同じアイコンかつ0.5秒以内)
                if effectiveName == lastTapName && diff < 0.5 {
                    close(save: true)
                }
                
                // 3. 今回の情報を保存
                lastTapTime = now
                lastTapName = effectiveName
            }
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor)
                }
            }
        #endif
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
    }
    
    private var popoverCategoryPicker: some View {
        Menu {
            categoryMenuItems
        } label: {
            ZStack {
                #if os(visionOS)
                // visionOS では常に標準の素材を使用
                Group {
                    if !shouldShowCategoryLabel {
                        // アイコンのみ
                        Image(systemName: currentCategoryIcon)
                            .frame(width: controlHeight, height: controlHeight)
                    } else {
                        // 横長ラベル
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
                .background(.regularMaterial, in: Capsule())
                #else
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
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
                    .glassEffect(.regular.interactive())
                    .clipShape(Capsule())
                } else {
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
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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
                    Label("Cancel", systemImage: "xmark")
                }
                #if !os(tvOS)
                .keyboardShortcut(.cancelAction)
                #endif
                .controlSize(.large)
                #if os(macOS)
                .adaptiveGlassButtonStyle()
                #endif
                
                Spacer()
                
                if showCategoryPicker {
                    sheetCategoryPicker
                        .controlSize(.large)
                        #if os(macOS)
                        .adaptiveGlassEffectStyle(.interactive)
                        #endif
                }
                
                Button {
                    close(save: true)
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                #if !os(tvOS)
                .keyboardShortcut(.defaultAction)
                #endif
                .controlSize(.large)
                #if os(macOS)
                .adaptiveGlassProminentButtonStyle()
                #endif
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
        Section {
            Picker("All Symbols", selection: $selectedCategoryID) {
                Label("All", systemImage: "square.grid.2x2").tag("all")
            }
            .pickerStyle(.inline)
            .labelStyle(.titleAndIcon)
        }
        
        Section {
            Picker("System Categories", selection: $selectedCategoryID) {
                ForEach(service.systemCategories) { cat in
                    if cat.id != "all" {
                        let iconName = service.effectiveName(for: cat.icon) ?? "square.grid.2x2"
                        Label(cat.label, systemImage: iconName).tag(cat.id)
                    }
                }
            }
            .pickerStyle(.inline)
            .labelStyle(.titleAndIcon)
        }
        
        if !customCategories.isEmpty {
            Section {
                Picker("Custom Categories", selection: $selectedCategoryID) {
                    ForEach(customCategories) { cat in
                        let iconName = service.effectiveName(for: cat.icon) ?? "square.grid.2x2"
                        Label(cat.label, systemImage: iconName).tag(cat.id.uuidString)
                    }
                }
                .pickerStyle(.inline)
                .labelStyle(.titleAndIcon)
            }
        }
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
    }

    
    private var searchBox: some View {
        #if os(tvOS)
        // tvOS 専用：極限までシンプルにした検索・カテゴリーバー
        HStack(spacing: 20) {
            // 検索入力エリア (虫眼鏡 + テキストフィールド)
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
            
            // カテゴリーピッカー
            if showCategoryPicker {
                sheetCategoryPicker
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(height: 80)
            }
        }
        #else
        // iOS/macOS/visionOS 向け Island 構成
        HStack(spacing: 12) {
            if showSearchBar {
                ZStack {
                    #if os(visionOS)
                    Color.clear
                        .background(.regularMaterial, in: Capsule())
                    #else
                    Color.clear
                        .adaptiveGlassEffectStyle(.regular, in: Capsule())
                    #endif
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.body.weight(.semibold))
                        
                        TextField(prompt, text: $searchText)
                            .textFieldStyle(.plain)
                            .background(Color.clear)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, controlHeight == 32 ? 6 : 10)
                }
                .frame(height: controlHeight)
                .overlay(
                    Capsule()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
}

// MARK: - Extension for Future APIs

public enum AdaptiveGlassStyle: Sendable {
    case regular
    case interactive
    case clear
    case clearInteractive
}

private extension View {
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
