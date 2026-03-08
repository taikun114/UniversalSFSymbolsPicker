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

struct ContentView: View {
    @State private var selectedIcon: String? = "star.fill"
    @State private var pickerMode: SFSymbolPickerDisplayMode = .sheet
    @State private var searchBarPosition: SFSymbolPickerSearchBarPosition = .bottom
    @State private var showSearchBarPopover = true
    @State private var showSearchBarSheet = true
    @State private var searchTextSheet = ""
    
    @State private var isSheetPresented = false
    @State private var isPopoverPresented = false
    @State private var showIconName = true
    
    // デモ用の設定
    @State private var variableValue: Double? = 1.0
    @State private var renderingModeOption: RenderingModeOption = .monochrome
    @State private var primaryColor: Color = .blue
    @State private var secondaryColor: Color = .red
    @State private var tertiaryColor: Color = .green
    @State private var useSecondaryColor = false
    @State private var useTertiaryColor = false
    
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
                                        primaryColor,
                                        useSecondaryColor ? secondaryColor : primaryColor,
                                        useTertiaryColor ? tertiaryColor : primaryColor
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
                                showIconName: showIconName,
                                renderingMode: renderingModeOption.mode,
                                primaryColor: primaryColor,
                                secondaryColor: useSecondaryColor ? secondaryColor : nil,
                                tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                                variableValue: $variableValue
                            )
                            .conditionalSearchable(show: showSearchBarSheet, text: $searchTextSheet)
                        }
                    }
                    .popover(isPresented: $isPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        SFSymbolPicker(
                            isPresented: $isPopoverPresented,
                            selection: $selectedIcon,
                            showAs: .popover,
                            searchBarPosition: searchBarPosition,
                            showSearchBar: showSearchBarPopover,
                            showIconName: showIconName,
                            renderingMode: renderingModeOption.mode,
                            primaryColor: primaryColor,
                            secondaryColor: useSecondaryColor ? secondaryColor : nil,
                            tertiaryColor: useTertiaryColor ? tertiaryColor : nil,
                            variableValue: $variableValue
                        )
                    }
                } header: {
                    Text("Picker Instance")
                }
                
                Section("Settings") {
                    Picker("Display Mode", selection: $pickerMode) {
                        Text("Sheet").tag(SFSymbolPickerDisplayMode.sheet)
                        Text("Popover").tag(SFSymbolPickerDisplayMode.popover)
                    }
                    .pickerStyle(.segmented)
                    
                    if pickerMode == .sheet {
                        Toggle("Show Search Bar", isOn: $showSearchBarSheet)
                    }
                    
                    Toggle("Show Icon Name", isOn: $showIconName)
                    
                    if pickerMode == .popover {
                        Toggle("Show Search Bar", isOn: $showSearchBarPopover)
                        
                        Picker("Search Bar Position", selection: $searchBarPosition) {
                            Text("Top").tag(SFSymbolPickerSearchBarPosition.top)
                            Text("Bottom").tag(SFSymbolPickerSearchBarPosition.bottom)
                        }
                    }
                }
                
                Section("Dynamic Rendering Demo") {
                    #if os(macOS)
                    Slider(value: Binding(
                        get: { variableValue ?? 0 },
                        set: { variableValue = $0 }
                    ), in: 0...1) {
                        Text("Variable Value: \(variableValue ?? 0, specifier: "%.2f")")
                    }
                    #else
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Variable Value: \(variableValue ?? 0, specifier: "%.2f")")
                        Slider(value: Binding(
                            get: { variableValue ?? 0 },
                            set: { variableValue = $0 }
                        ), in: 0...1)
                    }
                    #endif
                    
                    Picker("Rendering Mode", selection: $renderingModeOption) {
                        ForEach(RenderingModeOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }
                    
                    Group {
                        ColorPicker("Primary Color", selection: $primaryColor)
                        
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
            #if os(macOS)
            .frame(width: 400, height: 500)
            #elseif os(visionOS)
            .frame(width: 600, height: 800)
            #endif
        }
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
