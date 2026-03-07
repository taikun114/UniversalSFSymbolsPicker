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
    
    @State private var isPickerPresented = false
    
    // デモ用の設定
    @State private var variableValue: Double? = 0.5
    @State private var renderingModeOption: RenderingModeOption = .monochrome
    @State private var primaryColor: Color = .blue
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isPickerPresented = true
                    } label: {
                        HStack(spacing: 16) {
                            if let icon = selectedIcon {
                                Image(systemName: icon, variableValue: variableValue)
                                    .font(.title)
                                    .symbolRenderingMode(renderingModeOption.mode)
                                    .foregroundStyle(primaryColor)
                                    .frame(width: 44, height: 44)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(8)
                                
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
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Picker Instance")
                }
                
                Section("Settings") {
                    Picker("Display Mode", selection: $pickerMode) {
                        Text("Sheet").tag(SFSymbolPickerDisplayMode.sheet)
                        Text("Popover").tag(SFSymbolPickerDisplayMode.popover)
                    }
                    .pickerStyle(.segmented)
                    
                    if pickerMode == .popover {
                        Picker("Search Bar Position", selection: $searchBarPosition) {
                            Text("Top").tag(SFSymbolPickerSearchBarPosition.top)
                            Text("Bottom").tag(SFSymbolPickerSearchBarPosition.bottom)
                        }
                    }
                }
                
                Section("Dynamic Rendering Demo") {
                    VStack(alignment: .leading) {
                        Text("Variable Value: \(variableValue ?? 0, specifier: "%.2f")")
                        Slider(value: Binding(
                            get: { variableValue ?? 0 },
                            set: { variableValue = $0 }
                        ), in: 0...1)
                    }
                    
                    Picker("Rendering Mode", selection: $renderingModeOption) {
                        ForEach(RenderingModeOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }
                    
                    ColorPicker("Primary Color", selection: $primaryColor)
                }
            }
            .navigationTitle("USSP Demo")
            // ピッカーの起動（モードに応じて分岐）
            .sheet(isPresented: Binding(
                get: { isPickerPresented && pickerMode == .sheet },
                set: { if !$0 { isPickerPresented = false } }
            )) {
                NavigationStack {
                    SFSymbolPicker(
                        selection: $selectedIcon,
                        showAs: .sheet,
                        variableValue: $variableValue
                    )
                }
            }
            .popover(isPresented: Binding(
                get: { isPickerPresented && pickerMode == .popover },
                set: { if !$0 { isPickerPresented = false } }
            )) {
                SFSymbolPicker(
                    selection: $selectedIcon,
                    showAs: .popover,
                    searchBarPosition: searchBarPosition,
                    variableValue: $variableValue
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
