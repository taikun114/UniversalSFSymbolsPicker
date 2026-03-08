import SwiftUI

/// The display mode for the SF Symbols picker.
public enum SFSymbolPickerDisplayMode: Sendable {
    case sheet
    case popover
}

/// The position of the search bar in popover mode.
public enum SFSymbolPickerSearchBarPosition: Sendable {
    case top
    case bottom
}

public struct SFSymbolPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var isPresented: Bool
    @Binding var selection: String?
    let showAs: SFSymbolPickerDisplayMode
    let searchBarPosition: SFSymbolPickerSearchBarPosition
    let showSearchBar: Bool
    
    let prompt: String
    let showCategoryPicker: Bool
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
        if save {
            selection = temporarySelection
        }
        isPresented = false
        dismiss()
        presentationMode.wrappedValue.dismiss()
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
    
    public init(
        isPresented: Binding<Bool>,
        selection: Binding<String?>,
        showAs: SFSymbolPickerDisplayMode,
        searchBarPosition: SFSymbolPickerSearchBarPosition = .bottom,
        showSearchBar: Bool = true, // Only effective in Popover mode
        prompt: String = "Search Icons...",
        showCategoryPicker: Bool = true,
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
        self.searchBarPosition = searchBarPosition
        self.showSearchBar = showSearchBar
        self.prompt = prompt
        self.showCategoryPicker = showCategoryPicker
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
        symbolGrid
            .adaptiveSoftEdge()
            .adaptiveSafeAreaBar(edge: .top) {
                if showSearchBar && searchBarPosition == .top {
                    searchBox
                }
            }
            .adaptiveSafeAreaBar(edge: .bottom) {
                #if os(macOS)
                macOSBottomBar
                #else
                if showSearchBar && searchBarPosition == .bottom {
                    searchBox
                }
                #endif
            }
            #if !os(macOS)
            .navigationTitle("Select an Icon")
            #endif
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(macOS)
            .frame(width: 600, height: 500)
            #endif
            .toolbar {
                #if !os(macOS)
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
                #endif
            }
    }
    
    // MARK: - Popover View
    
    private var popoverView: some View {
        VStack(spacing: 0) {
            symbolGrid
                .adaptiveSafeAreaBar(edge: searchBarPosition == .top ? .top : .bottom) {
                    if showSearchBar || showCategoryPicker {
                        searchBox
                    }
                }
        }
        #if os(macOS)
        .frame(width: 400, height: 550) // macOS 専用の固定サイズ指定
        #elseif os(visionOS)
        .frame(width: 500, height: 600) // visionOS 専用の固定サイズ指定
        #else
        .frame(minWidth: 350, minHeight: 450)
        #endif
        .onDisappear {
            // ポップオーバーが閉じられた際に選択を確定
            selection = temporarySelection
        }
    }

    
    // MARK: - Components
    
    private var symbolGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 65))]
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
                // 最上部へスクロールするためのアンカー
                Color.clear
                    .frame(height: 0)
                    .id("top_anchor")
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredSymbols, id: \.self) { name in
                        symbolButton(for: name)
                    }
                }
                .padding(.horizontal)
                .padding(.top, (showSearchBar && searchBarPosition == .top) ? 0 : 16)
                .padding(.bottom, (showSearchBar && searchBarPosition == .bottom) || showAs == .sheet ? 0 : 16)
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
        let isSelected = temporarySelection == effectiveName

        return VStack(spacing: 8) {
            Image(systemName: effectiveName, variableValue: variableValue)
                .font(.system(size: 28))
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
                    .frame(height: 32, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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
    }

    
    private var sheetCategoryPicker: some View {
        Menu {
            categoryMenuItems
        } label: {
            #if os(macOS)
            HStack(spacing: 8) {
                Image(systemName: currentCategoryIcon)
                Text("Category: \(currentCategoryLabel)")
            }
            #else
            Label("Category", systemImage: currentCategoryIcon)
            #endif
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
                    if showSearchBar {
                        // アイコンのみ
                        Image(systemName: currentCategoryIcon)
                            .frame(width: controlHeight, height: controlHeight)
                    } else {
                        // 横長ラベル
                        HStack(spacing: 8) {
                            Image(systemName: currentCategoryIcon)
                            Text("Category: \(currentCategoryLabel)")
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
                        if showSearchBar {
                            Image(systemName: currentCategoryIcon)
                                .frame(width: controlHeight, height: controlHeight)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: currentCategoryIcon)
                                Text("Category: \(currentCategoryLabel)")
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
                        if showSearchBar {
                            Image(systemName: currentCategoryIcon)
                                .frame(width: controlHeight, height: controlHeight)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: currentCategoryIcon)
                                Text("Category: \(currentCategoryLabel)")
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
    }
    
    #if os(macOS)
    private var macOSBottomBar: some View {
        VStack(spacing: 0) {
            if showSearchBar && searchBarPosition == .bottom {
                searchBox
            }
            
            HStack {
                Button(role: .cancel) {
                    close(save: false)
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)
                .adaptiveLiquidGlassButtonStyle() // グラスエフェクト適用
                
                Spacer()
                
                if showCategoryPicker {
                    sheetCategoryPicker
                        .controlSize(.large)
                        .adaptiveLiquidGlassButtonStyle() // グラスエフェクト適用
                }
                
                Button {
                    close(save: true)
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .adaptiveLiquidGlassButtonStyle() // グラスエフェクト適用
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
    
    @ViewBuilder
    private var categoryMenuItems: some View {
        Picker("All Symbols", selection: $selectedCategoryID) {
            Label("All", systemImage: "square.grid.2x2").tag("all")
        }
        .pickerStyle(.inline)
        .labelStyle(.titleAndIcon)
        
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
        
        if !customCategories.isEmpty {
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
        HStack(spacing: 12) {
            // Island 1: Search Input (Capsule)
            if showSearchBar {
                ZStack {
                    #if os(visionOS)
                    // visionOS では常に標準の素材を使用
                    Color.clear
                        .background(.regularMaterial, in: Capsule())
                    #else
                    if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                        Color.clear
                            .adaptiveLiquidGlass(in: Capsule())
                    } else {
                        Group {
                            #if os(macOS)
                            VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                            #else
                            VisualEffectView(material: .systemThinMaterial)
                            #endif
                        }
                        .clipShape(Capsule())
                    }
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
                    .layoutPriority(1)
                    }

                    // Island 2: Category Picker (Circle/Capsule Button)
                    // シート時はツールバーにピッカーがあるため、ポップオーバー時のみ表示
                    if showCategoryPicker && showAs == .popover {
                    popoverCategoryPicker
                    .buttonStyle(.plain)
                    .frame(minWidth: showSearchBar ? controlHeight : 0)
                    .layoutPriority(showSearchBar ? 0 : 1)
                    }

            }
            .frame(maxWidth: .infinity) // 全体で中央寄せを可能にする
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, (showAs == .sheet && searchBarPosition == .bottom && osIsMacOS) ? 0 : 16)
            .fixedSize(horizontal: false, vertical: true)
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

private extension View {
    @ViewBuilder
    func adaptiveSafeAreaBar<Content: View>(edge: VerticalEdge, @ViewBuilder content: () -> Content) -> some View {
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
    func adaptiveLiquidGlassButtonStyle() -> some View {
        #if os(macOS)
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular.interactive())
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
        SFSymbolPicker(isPresented: .constant(true), selection: .constant("star.fill"), showAs: .sheet, searchBarPosition: .top, showSearchBar: true, showIconName: true, searchText: .constant(""))
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Sheet (Search Bottom)") {
    NavigationStack {
        SFSymbolPicker(isPresented: .constant(true), selection: .constant("star.fill"), showAs: .sheet, searchBarPosition: .bottom, showSearchBar: true, showIconName: true, searchText: .constant(""))
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Popover Mode (Bottom)") {
    SFSymbolPicker(isPresented: .constant(true), selection: .constant("heart.fill"), showAs: .popover, searchBarPosition: .bottom, showIconName: true, searchText: .constant(""))
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}

#Preview("Popover Mode (Top)") {
    SFSymbolPicker(isPresented: .constant(true), selection: .constant("gearshape.fill"), showAs: .popover, searchBarPosition: .top, showIconName: true, searchText: .constant(""))
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}
