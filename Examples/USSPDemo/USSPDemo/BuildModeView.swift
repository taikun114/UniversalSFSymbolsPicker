import SwiftUI
import UniversalSFSymbolsPicker

struct BuildModeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showCodeSheet = false
    
    // Width for split view
    @AppStorage("ussp_demo_build_mode_options_width") private var optionsWidth: Double = 400
    
    // MARK: - Options State
    @AppStorage("ussp_demo_build_mode_options") private var options = BuildModeOptions()
    
    @State private var showResetAlert = false
    
    // MARK: - Test Picker State
    @State private var isSheetPresented = false
    @State private var isPopoverPresented = false
    @State private var selectedIcon: String? = "star.fill"
    @State private var searchText = ""
    @State private var isCopied = false
    @State private var copyTask: Task<Void, Never>? = nil
    
    var body: some View {
        Group {
            if isCompact {
                // For compact width
                NavigationStack {
                    optionsForm
                        .navigationTitle("Build Mode")
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .adaptiveSafeAreaBar(edge: .bottom) {
                            Button(action: { showCodeSheet = true }) {
                                Text("Generate Code")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                            .background(.ultraThinMaterial)
                        }
                }
                .sheet(isPresented: $showCodeSheet) {
                    NavigationStack {
                        codeArea
                            .navigationTitle("Generated Code")
                            #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") {
                                        showCodeSheet = false
                                    }
                                }
                            }
                    }
                    .presentationDetents([.medium, .large])
                }
            } else {
                // For regular width (custom split view)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        optionsForm
                            .frame(width: CGFloat(max(250.0, min(optionsWidth, Double(geometry.size.width) - 250.0))))
                        
                        Divider()
                            .opacity(0)
                            .overlay(
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 20)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let newWidth = optionsWidth + Double(value.translation.width)
                                                // Width constraint
                                                optionsWidth = max(250.0, min(newWidth, Double(geometry.size.width) - 250.0))
                                            }
                                    )
                                    #if os(macOS)
                                    .onHover { isHovered in
                                        if isHovered {
                                            NSCursor.resizeLeftRight.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                    #endif
                            )
                            .zIndex(1)
                        
                        codeArea
                            .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("Build Mode")
            }
        }
    }
    
    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }
    
    // MARK: - Views
    
    private var optionsForm: some View {
        Form {
            Section(header: Text("Core Options")) {
                optionRow(title: "Display Mode", description: "Select how the symbol picker is presented.", isOn: $options.enableDisplayMode) {
                    Picker("Display Mode", selection: $options.displayMode) {
                        Text("Sheet").tag(SFSymbolPickerDisplayMode.sheet)
                        Text("Popover").tag(SFSymbolPickerDisplayMode.popover)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .adaptiveButtonSizingFlexible()
                }
                .onChange(of: options.enableDisplayMode) { _, newValue in
                    if !newValue { options.displayMode = .sheet }
                }
                
                optionRow(title: "Control Bar Position", description: "Select where the search bar and category picker are located.", isOn: $options.enableControlBarPosition) {
                    Picker("Control Bar Position", selection: $options.controlBarPosition) {
                        Text("Top").tag(SFSymbolPickerControlBarPosition.top)
                        Text("Bottom").tag(SFSymbolPickerControlBarPosition.bottom)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .adaptiveButtonSizingFlexible()
                }
                .onChange(of: options.enableControlBarPosition) { _, newValue in
                    if !newValue { options.controlBarPosition = .bottom }
                }
                
                boolOptionRow(title: "Show Search Bar", description: "Toggle whether the custom search bar is visible.", isEnableOn: $options.enableShowSearchBar, isValueOn: $options.showSearchBar)
                    .disabled(options.useSearchable)
                    .onChange(of: options.enableShowSearchBar) { _, newValue in
                        if !newValue { options.showSearchBar = true }
                    }
                
                Toggle(isOn: $options.useSearchable) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use .searchable")
                            .foregroundStyle(.primary)
                        Text("Use native searchable modifier and disable custom search bar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: options.useSearchable) { _, newValue in
                    if newValue {
                        options.enableShowSearchBar = true
                        options.showSearchBar = false
                    }
                }
            }
            
            Section(header: Text("Categories & UI")) {
                boolOptionRow(title: "Show Category Picker", description: "Toggle whether to display the category menu.", isEnableOn: $options.enableShowCategoryPicker, isValueOn: $options.showCategoryPicker)
                    .onChange(of: options.enableShowCategoryPicker) { _, newValue in
                        if !newValue { options.showCategoryPicker = true }
                    }
                
                boolOptionRow(title: "Show Category Section Label", description: "Display section headers in the category menu.", isEnableOn: $options.enableShowCategorySectionLabel, isValueOn: $options.showCategorySectionLabel)
                    .onChange(of: options.enableShowCategorySectionLabel) { _, newValue in
                        if !newValue { options.showCategorySectionLabel = true }
                    }
                
                optionRow(title: "Category Label Visibility", description: "Select how the category label is displayed.", isOn: $options.enableCategoryLabelVisibility) {
                    Picker("Category Label Visibility", selection: $options.categoryLabelVisibility) {
                        Text("Default").tag(SFSymbolPickerCategoryLabelVisibility.default)
                        Text("Visible").tag(SFSymbolPickerCategoryLabelVisibility.visible)
                        Text("Hidden").tag(SFSymbolPickerCategoryLabelVisibility.hidden)
                    }
                    .pickerStyle(.menu)
                }
                .onChange(of: options.enableCategoryLabelVisibility) { _, newValue in
                    if !newValue { options.categoryLabelVisibility = .default }
                }
                
                optionRow(title: "Category Label Style", description: "Select the style of the category label.", isOn: $options.enableCategoryLabelStyle) {
                    Picker("Category Label Style", selection: $options.categoryLabelStyle) {
                        Text("Both").tag(SFSymbolPickerCategoryLabelStyle.both)
                        Text("Title Only").tag(SFSymbolPickerCategoryLabelStyle.titleOnly)
                        Text("Name Only").tag(SFSymbolPickerCategoryLabelStyle.nameOnly)
                    }
                    .pickerStyle(.menu)
                }
                .onChange(of: options.enableCategoryLabelStyle) { _, newValue in
                    if !newValue { options.categoryLabelStyle = .both }
                }
                
                boolOptionRow(title: "Show Icon Name", description: "Toggle whether to display the name of each symbol.", isEnableOn: $options.enableShowIconName, isValueOn: $options.showIconName)
                    .onChange(of: options.enableShowIconName) { _, newValue in
                        if !newValue { options.showIconName = true }
                    }
                
                boolOptionRow(title: "Exclude Restricted", description: "Hide symbols with usage restrictions.", isEnableOn: $options.enableExcludeRestricted, isValueOn: $options.excludeRestricted)
                    .onChange(of: options.enableExcludeRestricted) { _, newValue in
                        if !newValue { options.excludeRestricted = false }
                    }
                
                optionRow(title: "Icon Scale", description: "Change the display size of icons in the grid.", isOn: $options.enableIconScale) {
                    Stepper(value: $options.iconScale, in: 1...10) {
                        HStack {
                            Text("Scale")
                            Spacer()
                            Text("\(options.iconScale)")
                                .foregroundStyle(options.enableIconScale ? .secondary : .tertiary)
                        }
                    }
                }
                .onChange(of: options.enableIconScale) { _, newValue in
                    if !newValue { options.iconScale = 5 }
                }
                
                boolOptionRow(title: "Show Recents", description: "Toggle the recently used icons category.", isEnableOn: $options.enableShowRecents, isValueOn: $options.showRecents)
                    .onChange(of: options.enableShowRecents) { _, newValue in
                        if !newValue { options.showRecents = false }
                    }
                
                optionRow(title: "Max Recents", description: "Maximum number of recently used icons.", isOn: $options.enableMaxRecents) {
                    Stepper(value: $options.maxRecents, in: 1...100) {
                        HStack {
                            Text("Max")
                            Spacer()
                            Text("\(options.maxRecents)")
                                .foregroundStyle(options.enableMaxRecents ? .secondary : .tertiary)
                        }
                    }
                }
                .onChange(of: options.enableMaxRecents) { _, newValue in
                    if !newValue { options.maxRecents = 20 }
                }
            }
            
            Section(header: Text("Styling")) {
                optionRow(title: "Rendering Mode", description: "Select the rendering mode for the symbol.", isOn: $options.enableRenderingMode) {
                    Picker("Rendering Mode", selection: $options.renderingModeOption) {
                        Text("Monochrome").tag(RenderingModeOption.monochrome)
                        Text("Hierarchical").tag(RenderingModeOption.hierarchical)
                        Text("Palette").tag(RenderingModeOption.palette)
                        Text("Multicolor").tag(RenderingModeOption.multicolor)
                    }
                    .pickerStyle(.menu)
                }
                .onChange(of: options.enableRenderingMode) { _, newValue in
                    if !newValue { options.renderingModeOption = .monochrome }
                }
                
                boolOptionRow(title: "Gradient Rendering", description: "Enable gradient rendering.", isEnableOn: $options.enableIsGradient, isValueOn: $options.isGradient)
                    .onChange(of: options.enableIsGradient) { _, newValue in
                        if !newValue { options.isGradient = false }
                    }
                
                optionRow(title: "Primary Color", description: "Set the primary color.", isOn: $options.enablePrimaryColor) {
                    #if os(macOS) || os(iOS) || os(visionOS)
                    ColorPicker("Primary Color", selection: .constant(.blue))
                    #else
                    Text("Not available")
                    #endif
                }
                
                optionRow(title: "Secondary Color", description: "Set the secondary color.", isOn: $options.enableSecondaryColor) {
                    #if os(macOS) || os(iOS) || os(visionOS)
                    ColorPicker("Secondary Color", selection: .constant(.red))
                    #else
                    Text("Not available")
                    #endif
                }
                
                optionRow(title: "Tertiary Color", description: "Set the tertiary color.", isOn: $options.enableTertiaryColor) {
                    #if os(macOS) || os(iOS) || os(visionOS)
                    ColorPicker("Tertiary Color", selection: .constant(.green))
                    #else
                    Text("Not available")
                    #endif
                }
                
                Toggle(isOn: $options.enableVariableValue) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Variable Value")
                            .foregroundStyle(.primary)
                        Text("Bind a value to update the corresponding symbol in real time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset All Options")
                        Spacer()
                    }
                }
                .alert("Reset Options", isPresented: $showResetAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        options = BuildModeOptions()
                    }
                } message: {
                    Text("Are you sure you want to reset all options to their default values?")
                }
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .top) {
            testPickerButton
        }
    }
    
    private var testPickerButton: some View {
        Button {
            if options.displayMode == .sheet {
                isSheetPresented = true
            } else {
                isPopoverPresented = true
            }
        } label: {
            HStack(spacing: 8) {
                if let icon = selectedIcon {
                    Image(systemName: icon, variableValue: options.enableVariableValue ? 0.7 : nil)
                        .font(.title2)
                        .symbolRenderingMode(options.enableRenderingMode ? options.renderingModeOption.mode : .monochrome)
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
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isSheetPresented) {
            if options.useSearchable {
                NavigationStack {
                    buildPicker(isPresented: $isSheetPresented)
                        .searchable(text: $searchText)
                }
            } else {
                NavigationStack {
                    buildPicker(isPresented: $isSheetPresented)
                }
            }
        }
        .popover(isPresented: $isPopoverPresented) {
            if options.useSearchable {
                NavigationStack {
                    buildPicker(isPresented: $isPopoverPresented)
                        .searchable(text: $searchText)
                }
                .frame(minWidth: 400, minHeight: 500)
            } else {
                NavigationStack {
                    buildPicker(isPresented: $isPopoverPresented)
                }
                .frame(minWidth: 400, minHeight: 500)
            }
        }
    }
    
    @ViewBuilder
    private func buildPicker(isPresented: Binding<Bool>) -> some View {
        SFSymbolPicker(
            isPresented: isPresented,
            selection: $selectedIcon,
            showAs: options.enableDisplayMode ? options.displayMode : .sheet,
            controlBarPosition: options.enableControlBarPosition ? options.controlBarPosition : .bottom,
            showSearchBar: options.useSearchable ? false : (options.enableShowSearchBar ? options.showSearchBar : true),
            showCategoryPicker: options.enableShowCategoryPicker ? options.showCategoryPicker : true,
            showCategorySectionLabel: options.enableShowCategorySectionLabel ? options.showCategorySectionLabel : true,
            categoryLabelVisibility: options.enableCategoryLabelVisibility ? options.categoryLabelVisibility : .default,
            categoryLabelStyle: options.enableCategoryLabelStyle ? options.categoryLabelStyle : .both,
            showIconName: options.enableShowIconName ? options.showIconName : true,
            excludeRestricted: options.enableExcludeRestricted ? options.excludeRestricted : false,
            showRecents: options.enableShowRecents ? options.showRecents : false,
            maxRecents: options.enableMaxRecents ? options.maxRecents : 20,
            renderingMode: options.enableRenderingMode ? options.renderingModeOption.mode : .monochrome,
            isGradient: options.enableIsGradient ? options.isGradient : false,
            primaryColor: options.enablePrimaryColor ? .blue : .primary,
            secondaryColor: options.enableSecondaryColor ? .red : nil,
            tertiaryColor: options.enableTertiaryColor ? .green : nil,
            variableValue: .constant(options.enableVariableValue ? 0.7 : nil),
            searchText: $searchText,
            iconScale: options.enableIconScale ? options.iconScale : 5
        )
    }
    
    private var codeArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SwiftUI Code")
                    .font(.headline)
                Spacer()
                Button {
                    let generatedCode = CodeGenerator.generate(options: options)
                    #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(generatedCode, forType: .string)
                    #elseif os(iOS) || os(visionOS)
                    UIPasteboard.general.string = generatedCode
                    #endif
                    
                    isCopied = true
                    copyTask?.cancel()
                    copyTask = Task {
                        try? await Task.sleep(for: .seconds(3))
                        if !Task.isCancelled {
                            await MainActor.run {
                                isCopied = false
                            }
                        }
                    }
                } label: {
                    Label("Copy Code", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.thickMaterial)
            
            GeometryReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    Text(CodeGenerator.generate(options: options))
                        .font(.system(.body, design: .monospaced))
                        .fixedSize(horizontal: true, vertical: false)
                        .padding()
                        .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .topLeading)
                        .textSelection(.enabled)
                }
            }
            .background(Color.primary.opacity(0.05))
        }
    }
    
    // MARK: - Helpers
    
    private func optionRow<Content: View>(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        isOn: Binding<Bool>,
        isMandatory: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if !isMandatory {
                Toggle(title, isOn: isOn)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle((isMandatory || isOn.wrappedValue) ? .primary : .secondary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle((isMandatory || isOn.wrappedValue) ? .secondary : .tertiary)
                }
                
                content()
                    .disabled(!isMandatory && !isOn.wrappedValue)
                    .foregroundStyle((isMandatory || isOn.wrappedValue) ? .primary : .secondary)
                    .tint((isMandatory || isOn.wrappedValue) ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func boolOptionRow(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        isEnableOn: Binding<Bool>,
        isValueOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Toggle(title, isOn: isEnableOn)
                .toggleStyle(.checkbox)
                .labelsHidden()
            
            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: isValueOn) {
                    Text(title)
                        .foregroundStyle(isEnableOn.wrappedValue ? .primary : .secondary)
                }
                .disabled(!isEnableOn.wrappedValue)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(isEnableOn.wrappedValue ? .secondary : .tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BuildModeView()
}
