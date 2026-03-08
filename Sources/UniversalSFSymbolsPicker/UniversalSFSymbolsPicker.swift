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
    
    // Internal State
    @State private var searchText = ""
    @State private var selectedCategoryID: String
    @State private var temporarySelection: String?
    private let service = SFSymbolService.shared
    
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
        variableValue: Binding<Double?> = .constant(nil)
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
            symbolGrid
            
            #if os(macOS)
            // macOS 専用の下部ボタンエリア
            Divider()
            HStack {
                Button(role: .cancel) {
                    close(save: false)
                } label: {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)
                
                Spacer()
                
                if showCategoryPicker {
                    sheetCategoryPicker
                        .controlSize(.large)
                }
                
                doneButton
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
            .padding()
            #endif
        }
        .navigationTitle("Select an Icon")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
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
                    if showSearchBar {
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
        
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredSymbols, id: \.self) { name in
                    symbolButton(for: name)
                }
            }
            .padding()
        }
    }
    
    private func symbolButton(for name: String) -> some View {
        let effectiveName = service.effectiveName(for: name) ?? name
        let isSelected = temporarySelection == effectiveName
        
        return Button {
            temporarySelection = effectiveName
        } label: {
            VStack(spacing: 8) {
                Image(systemName: effectiveName, variableValue: variableValue)
                    .font(.system(size: 28))
                    .symbolRenderingMode(isSelected ? .monochrome : renderingMode)
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(primaryColor))

                if showIconName {
                    // ドットの位置で折り返しやすくするためにゼロ幅スペースを挿入
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
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor) // 不透明なアクセントカラー
            }
        }
    }
    
    private var sheetCategoryPicker: some View {
        Menu {
            categoryMenuItems
        } label: {
            Label("Category", systemImage: currentCategoryIcon)
        }
    }
    
    private var popoverCategoryPicker: some View {
        Menu {
            categoryMenuItems
        } label: {
            ZStack {
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    Image(systemName: currentCategoryIcon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        #if !os(visionOS)
                        .glassEffect(.regular.interactive())
                        #endif
                } else {
                    Image(systemName: currentCategoryIcon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background {
                            #if os(macOS)
                            VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                                .clipShape(Circle())
                            #elseif os(visionOS)
                            Color.clear.background(.ultraThinMaterial, in: Circle())
                            #else
                            Circle().fill(.thinMaterial)
                            #endif
                        }
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Circle())
        }
    }
    
    @ViewBuilder
    private var categoryMenuItems: some View {
        Picker("All Symbols", selection: $selectedCategoryID) {
            Label("All", systemImage: "square.grid.2x2").tag("all")
        }
        .pickerStyle(.inline)
        
        Picker("System Categories", selection: $selectedCategoryID) {
            ForEach(service.systemCategories) { cat in
                if cat.id != "all" {
                    Label(cat.label, systemImage: cat.icon).tag(cat.id)
                }
            }
        }
        .pickerStyle(.inline)
        
        if !customCategories.isEmpty {
            Picker("Custom Categories", selection: $selectedCategoryID) {
                ForEach(customCategories) { cat in
                    Label(cat.label, systemImage: cat.icon).tag(cat.id.uuidString)
                }
            }
            .pickerStyle(.inline)
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
            ZStack {
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    Color.clear
                        #if !os(visionOS)
                        .adaptiveLiquidGlass(in: Capsule())
                        #endif
                } else {
                    Group {
                        #if os(macOS)
                        VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                        #elseif os(visionOS)
                        Color.clear.background(.ultraThinMaterial)
                        #else
                        VisualEffectView(material: .systemThinMaterial)
                        #endif
                    }
                    .clipShape(Capsule())
                }
                
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
                .padding(.vertical, 10)
            }
            .frame(height: 40)
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .layoutPriority(1)
            
            // Island 2: Category Picker (Circle Button)
            if showCategoryPicker {
                popoverCategoryPicker
                    .buttonStyle(.plain)
                    .frame(width: 40) // 幅を固定して潰れないようにする
                    .layoutPriority(0)
            }
            }
            .padding(.horizontal, 16) // 左右パディングを少し広めに
            .padding(.vertical, 12)
            .fixedSize(horizontal: false, vertical: true)

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
}

// MARK: - Previews

#Preview("Sheet Mode") {
    NavigationStack {
        SFSymbolPicker(isPresented: .constant(true), selection: .constant("star.fill"), showAs: .sheet, showIconName: true)
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Popover Mode (Bottom)") {
    SFSymbolPicker(isPresented: .constant(true), selection: .constant("heart.fill"), showAs: .popover, searchBarPosition: .bottom, showIconName: true)
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}

#Preview("Popover Mode (Top)") {
    SFSymbolPicker(isPresented: .constant(true), selection: .constant("gearshape.fill"), showAs: .popover, searchBarPosition: .top, showIconName: true)
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}
