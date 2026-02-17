import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var presetManager = PresetManager()
    @StateObject private var folderManager = FolderManager()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSuccessMessage = false
    @State private var validationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with theme toggle
                    headerView
                    
                    // Main form
                    VStack(spacing: 16) {
                        inputFieldsSection
                        presetSection
                        folderLocationSection
                        actionButtonsSection
                        
                        if showSuccessMessage {
                            successMessageView
                        }
                        
                        if !validationErrors.isEmpty {
                            validationErrorsView
                        }
                        
                        if settings.showFolderPreview {
                            folderPreviewSection
                        }
                        
                        // Extended Folder Structure Preview section
                        extendedFolderPreviewSection
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Powered by label
                    poweredByLabel
                }
            }
        }
        .preferredColorScheme(settings.theme)
        .onAppear {
            presetManager.loadPresets()
        }
        .onDisappear {
            settings.saveSettings()
        }
        .alert("Alert", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("DIT FolderGen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Professional Video Production Folder Generator")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Theme toggle
            Picker("Theme", selection: Binding<Int>(
                get: {
                    if settings.theme == .dark { return 1 }
                    else if settings.theme == .light { return 0 }
                    else { return 2 }
                },
                set: { newValue in
                    switch newValue {
                    case 0: settings.theme = .light
                    case 1: settings.theme = .dark
                    default: settings.theme = nil
                    }
                }
            )) {
                Text("Light").tag(0)
                Text("Dark").tag(1)
                Text("System").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
        .padding(.horizontal)
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Project Details")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Project Name*:")
                        .frame(width: 120, alignment: .leading)
                    TextField("Enter project name", text: $settings.projectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: settings.projectName) { _ in validateInputs() }
                }
                
                HStack {
                    Text("Showcode*:")
                        .frame(width: 120, alignment: .leading)
                    TextField("ABC", text: Binding<String>(
                        get: { settings.showcode },
                        set: { newValue in
                            let filtered = String(newValue.prefix(3).uppercased().filter { $0.isLetter })
                            settings.showcode = filtered
                            validateInputs()
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Episode:")
                        .frame(width: 120, alignment: .leading)
                    TextField("EP001 (optional)", text: $settings.episode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: settings.episode) { _ in validateInputs() }
                }
                
                HStack {
                    Text("Day:")
                        .frame(width: 120, alignment: .leading)
                    TextField("Day001", text: $settings.day)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: settings.day) { _ in validateInputs() }
                }
                
                HStack {
                    Text("Unit:")
                        .frame(width: 120, alignment: .leading)
                    Picker("Unit", selection: $settings.unit) {
                        ForEach(settings.units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: settings.unit) { _ in validateInputs() }
                }
                
                HStack {
                    Text("CG Number:")
                        .frame(width: 120, alignment: .leading)
                    TextField("CG01 (optional)", text: $settings.cgNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: settings.cgNumber) { _ in validateInputs() }
                }
                
                HStack {
                    Text("Date:")
                        .frame(width: 120, alignment: .leading)
                    DatePicker("", selection: $settings.selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .onChange(of: settings.selectedDate) { _ in validateInputs() }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var presetSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Folder Structure Preset")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text("Preset:")
                    .frame(width: 120, alignment: .leading)
                Picker("Preset", selection: $settings.selectedPreset) {
                    ForEach(presetManager.presets, id: \.id) { preset in
                        Text(preset.preset_name).tag(preset)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Show preset folders
            VStack(alignment: .leading, spacing: 4) {
                Text("Folders to create:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(settings.selectedPreset.folders, id: \.self) { folder in
                    HStack {
                        Text("📁")
                        Text(folder)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                    }
                    .padding(.leading)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var folderLocationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Folder Location")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text("Base Path*:")
                    .frame(width: 120, alignment: .leading)
                
                HStack {
                    Text(settings.baseFolderPath.isEmpty ? "No folder selected" : settings.baseFolderPath)
                        .foregroundColor(settings.baseFolderPath.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Choose Folder") {
                        selectBaseFolder()
                    }
                }
            }
            
            HStack {
                Text("Second Location:")
                    .frame(width: 120, alignment: .leading)
                
                HStack {
                    Text(settings.secondFolderPath.isEmpty ? "No folder selected (optional)" : settings.secondFolderPath)
                        .foregroundColor(settings.secondFolderPath.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Choose Folder") {
                        selectSecondFolder()
                    }
                    
                    if !settings.secondFolderPath.isEmpty {
                        Button("Clear") {
                            settings.secondFolderPath = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            HStack {
                Text("Third Location:")
                    .frame(width: 120, alignment: .leading)
                
                HStack {
                    Text(settings.thirdFolderPath.isEmpty ? "No folder selected (optional)" : settings.thirdFolderPath)
                        .foregroundColor(settings.thirdFolderPath.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Choose Folder") {
                        selectThirdFolder()
                    }
                    
                    if !settings.thirdFolderPath.isEmpty {
                        Button("Clear") {
                            settings.thirdFolderPath = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            // Show generated folder structure preview
            if !settings.baseFolderPath.isEmpty && isFormValid {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generated folder structure:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("📁 \(settings.projectNameForFolder())/")
                            .font(.system(.body, design: .monospaced))
                        Text("   └── 📁 \(generateFolderName())/")
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                    .border(Color.gray.opacity(0.3), width: 1)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button("Create Folder") {
                createFolder()
            }
            .disabled(!canCreateFolder)
            .buttonStyle(.borderedProminent)
            
            if !settings.createdFolderPath.isEmpty {
                Button("Open in Finder") {
                    NSWorkspace.shared.openFile(settings.createdFolderPath)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
    
    private var successMessageView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("✅ Folder Created!")
                .font(.headline)
                .foregroundColor(.green)
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showSuccessMessage = false
            }
        }
    }
    
    private var validationErrorsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Validation Errors:")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            ForEach(validationErrors, id: \.self) { error in
                Text("• \(error)")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var folderPreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Folder Structure Preview")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Export PDF") {
                        exportToPDF()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export CSV") {
                        exportToCSV()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(settings.folderStructure) { item in
                        FolderTreeRow(item: item)
                    }
                }
            }
            .frame(maxHeight: 300)
            .padding()
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .border(Color.gray.opacity(0.3), width: 1)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var poweredByLabel: some View {
        Text("Powered by Nomad Jay")
            .font(.caption)
            .foregroundColor(.secondary)
            .opacity(0.7)
            .padding(.bottom)
    }
    
    // MARK: - Helper Functions
    
    private var isFormValid: Bool {
        return !settings.projectName.isEmpty && 
               settings.showcode.count == 3 && 
               !settings.day.isEmpty &&
               !settings.baseFolderPath.isEmpty
    }
    
    private var canCreateFolder: Bool {
        return isFormValid && validationErrors.isEmpty
    }
    
    private func validateInputs() {
        validationErrors.removeAll()
        
        if settings.projectName.isEmpty {
            validationErrors.append("Project name is required")
        }
        
        if settings.showcode.count != 3 {
            validationErrors.append("Showcode must be exactly 3 letters")
        }
        
        if settings.day.isEmpty {
            validationErrors.append("Day is required")
        }
        
        if settings.baseFolderPath.isEmpty {
            validationErrors.append("Base folder path is required")
        }
        
        // Check for invalid characters - allow spaces in project name
        let invalidChars = CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "_ "))
        
        if settings.projectName.rangeOfCharacter(from: invalidChars) != nil {
            validationErrors.append("Project name contains invalid characters (only letters, numbers, spaces, and underscores allowed)")
        }
        
        if settings.day.rangeOfCharacter(from: invalidChars) != nil {
            validationErrors.append("Day contains invalid characters (only letters, numbers, and underscores allowed)")
        }
        
        if !settings.episode.isEmpty && settings.episode.rangeOfCharacter(from: invalidChars) != nil {
            validationErrors.append("Episode contains invalid characters (only letters, numbers, and underscores allowed)")
        }
    }
    
    private func generateFolderName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: settings.selectedDate)
        
        var folderName = "\(settings.showcode)_\(dateString)"
        
        // Handle different unit types and folder naming logic
        if settings.unit == "CG" && !settings.cgNumber.isEmpty {
            folderName += "_\(settings.cgNumber)_CG"
        } else if settings.unit == "TEST" {
            folderName += "_TEST01_Day999_TEST"
        } else {
            if !settings.episode.isEmpty {
                folderName += "_\(settings.episode)"
            }
            folderName += "_\(settings.day)_\(settings.unit)"
        }
        
        return folderName
    }
    
    private func selectBaseFolder() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = true
            panel.prompt = "Choose Folder"
            panel.message = "Select the base folder where the project folder will be created"
            
            if !self.settings.baseFolderPath.isEmpty {
                panel.directoryURL = URL(fileURLWithPath: self.settings.baseFolderPath)
            }
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        self.settings.baseFolderPath = url.path
                        self.validateInputs()
                    }
                }
            }
        }
    }
    
    private func selectSecondFolder() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = true
            panel.prompt = "Choose Second Location"
            panel.message = "Select an optional second folder location"
            
            if !self.settings.secondFolderPath.isEmpty {
                panel.directoryURL = URL(fileURLWithPath: self.settings.secondFolderPath)
            }
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        self.settings.secondFolderPath = url.path
                    }
                }
            }
        }
    }
    
    private func selectThirdFolder() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = true
            panel.prompt = "Choose Third Location"
            panel.message = "Select an optional third folder location"
            
            if !self.settings.thirdFolderPath.isEmpty {
                panel.directoryURL = URL(fileURLWithPath: self.settings.thirdFolderPath)
            }
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        self.settings.thirdFolderPath = url.path
                    }
                }
            }
        }
    }
    
    private func selectFolderToPreview() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false
            panel.prompt = "Choose Folder to Preview"
            panel.message = "Select any folder to preview its structure"
            
            if !self.settings.previewFolderPath.isEmpty {
                panel.directoryURL = URL(fileURLWithPath: self.settings.previewFolderPath)
            }
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        self.settings.previewFolderPath = url.path
                        self.settings.showPreviewSection = true
                        self.loadPreviewFolderStructure(at: url.path)
                    }
                }
            }
        }
    }
    
    private func createFolder() {
        guard canCreateFolder else { return }
        
        let folderName = generateFolderName()
        let projectName = settings.projectNameForFolder()
        
        // Collect all locations
        var locations = [settings.baseFolderPath]
        if !settings.secondFolderPath.isEmpty {
            locations.append(settings.secondFolderPath)
        }
        if !settings.thirdFolderPath.isEmpty {
            locations.append(settings.thirdFolderPath)
        }
        
        // Create folder structure at all locations
        folderManager.createFolderStructureAtMultipleLocations(
            projectName: projectName,
            folderName: folderName,
            folders: settings.selectedPreset.folders,
            locations: locations
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    let projectFolderPath = (settings.baseFolderPath as NSString).appendingPathComponent(projectName)
                    let fullPath = (projectFolderPath as NSString).appendingPathComponent(folderName)
                    settings.createdFolderPath = fullPath
                    showSuccessMessage = true
                    loadFolderStructure(at: projectFolderPath)
                    settings.showFolderPreview = true
                } else {
                    alertMessage = error ?? "Failed to create folder"
                    showAlert = true
                }
            }
        }
    }
    
    private func loadFolderStructure(at path: String) {
        folderManager.getFolderStructure(at: path) { structure in
            DispatchQueue.main.async {
                settings.folderStructure = structure
            }
        }
    }
    
    private func loadPreviewFolderStructure(at path: String) {
        folderManager.getFolderStructure(at: path) { structure in
            DispatchQueue.main.async {
                settings.previewFolderStructure = structure
            }
        }
    }
    
    private func exportToPDF() {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(self.generateFolderName())_structure.pdf"
            panel.prompt = "Export PDF"
            panel.message = "Save folder structure as PDF"
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    self.folderManager.exportToPDF(
                        folderStructure: self.settings.folderStructure,
                        projectInfo: self.generateProjectInfo(),
                        to: url
                    ) { success in
                        DispatchQueue.main.async {
                            if !success {
                                self.alertMessage = "Failed to export PDF"
                                self.showAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func exportToCSV() {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.nameFieldStringValue = "\(self.generateFolderName())_structure.csv"
            panel.prompt = "Export CSV"
            panel.message = "Save folder structure as CSV"
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    self.folderManager.exportToCSV(
                        folderStructure: self.settings.folderStructure,
                        to: url
                    ) { success in
                        DispatchQueue.main.async {
                            if !success {
                                self.alertMessage = "Failed to export CSV"
                                self.showAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func generateProjectInfo() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        var info = "Project: \(settings.projectName)\n"
        info += "Showcode: \(settings.showcode)\n"
        if !settings.episode.isEmpty {
            info += "Episode: \(settings.episode)\n"
        }
        info += "Day: \(settings.day)\n"
        info += "Unit: \(settings.unit)\n"
        if !settings.cgNumber.isEmpty {
            info += "CG Number: \(settings.cgNumber)\n"
        }
        info += "Date: \(dateFormatter.string(from: settings.selectedDate))\n"
        info += "Folder: \(generateFolderName())"
        
        return info
    }
    
    // MARK: - Extended Folder Preview Section
    
    private var extendedFolderPreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Extended Folder Structure Preview")
                    .font(.headline)
                
                Spacer()
                
                Button("Select Folder to Preview") {
                    selectFolderToPreview()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if !settings.previewFolderPath.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Selected folder:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Clear") {
                            settings.previewFolderPath = ""
                            settings.previewFolderStructure = []
                            settings.showPreviewSection = false
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text(settings.previewFolderPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                if settings.showPreviewSection && !settings.previewFolderStructure.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(settings.previewFolderStructure) { item in
                                FolderTreeRow(item: item)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .border(Color.gray.opacity(0.3), width: 1)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct FolderTreeRow: View {
    let item: FolderItem
    
    var body: some View {
        HStack {
            Text(levelPrefix(for: item.level))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text(item.isDirectory ? "📁" : "📄")
            
            Text(item.name)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Text(item.size)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
    
    private func levelPrefix(for level: Int) -> String {
        if level == 0 {
            return ""
        }
        
        var prefix = ""
        for i in 0..<level {
            if i == level - 1 {
                prefix += "└── "
            } else {
                prefix += "│   "
            }
        }
        return prefix
    }
}