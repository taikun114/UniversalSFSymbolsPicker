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
    
    @Binding var selection: String?
    let showAs: SFSymbolPickerDisplayMode
    let searchBarPosition: SFSymbolPickerSearchBarPosition
    
    let prompt: String
    let showCategoryPicker: Bool
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
    private let service = SFSymbolService.shared
    
    public init(
        selection: Binding<String?>,
        showAs: SFSymbolPickerDisplayMode,
        searchBarPosition: SFSymbolPickerSearchBarPosition = .bottom,
        prompt: String = "Search Icons...",
        showCategoryPicker: Bool = true,
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
        self._selection = selection
        self.showAs = showAs
        self.searchBarPosition = searchBarPosition
        self.prompt = prompt
        self.showCategoryPicker = showCategoryPicker
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
            .navigationTitle("Select an Icon")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if showCategoryPicker {
                    ToolbarItem(placement: .primaryAction) {
                        categoryMenuPicker
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    doneButton
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
#if os(iOS)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(prompt))
#else
            .searchable(text: $searchText, prompt: Text(prompt))
#endif
    }
    
    // MARK: - Popover View
    
    private var popoverView: some View {
        VStack(spacing: 0) {
            symbolGrid
                .adaptiveSafeAreaBar(edge: searchBarPosition == .top ? .top : .bottom) {
                    searchBox.padding()
                }
        }
        .frame(minWidth: 350, minHeight: 450)
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
        return Button {
            selection = effectiveName
        } label: {
            VStack(spacing: 8) {
                Image(systemName: effectiveName, variableValue: variableValue)
                    .font(.system(size: 28))
                    .symbolRenderingMode(renderingMode)
                    .foregroundStyle(primaryColor, secondaryColor ?? primaryColor, tertiaryColor ?? primaryColor)
                
                Text(effectiveName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if selection == effectiveName {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var categoryMenuPicker: some View {
        Menu {
            Picker("Category", selection: $selectedCategoryID) {
                Label("All", systemImage: "square.grid.2x2").tag("all")
                
                Divider()
                
                ForEach(service.systemCategories) { cat in
                    if cat.id != "all" {
                        Label(cat.label, systemImage: cat.icon).tag(cat.id)
                    }
                }
                
                if !customCategories.isEmpty {
                    Divider()
                    ForEach(customCategories) { cat in
                        Label(cat.label, systemImage: cat.icon).tag(cat.id.uuidString)
                    }
                }
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "square.grid.2x2")
        }
    }
    
    private var doneButton: some View {
        Group {
            if #available(iOS 19.0, macOS 16.0, tvOS 19.0, watchOS 12.0, visionOS 3.0, *) {
                Button(role: .confirm) {
                    dismiss()
                } label: {
                    EmptyView()
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var searchBox: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body.weight(.semibold))
                
                TextField(prompt, text: $searchText)
                    .textFieldStyle(.plain)
                
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
            
            if showCategoryPicker {
                categoryMenuPicker
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background {
            ZStack {
                #if os(macOS)
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                #elseif os(visionOS)
                Color.clear.background(.ultraThinMaterial)
                #else
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                    Color.clear.adaptiveLiquidGlass(in: .rect(cornerRadius: 22))
                } else {
                    VisualEffectView(material: .systemUltraThinMaterial)
                }
                #endif
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
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
        SFSymbolPicker(selection: .constant("star.fill"), showAs: .sheet)
    }
    #if os(macOS)
    .frame(width: 600, height: 500)
    #endif
}

#Preview("Popover Mode (Bottom)") {
    SFSymbolPicker(selection: .constant("heart.fill"), showAs: .popover, searchBarPosition: .bottom)
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}

#Preview("Popover Mode (Top)") {
    SFSymbolPicker(selection: .constant("gearshape.fill"), showAs: .popover, searchBarPosition: .top)
    #if os(macOS)
    .frame(width: 400, height: 500)
    #endif
}
