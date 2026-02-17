import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var projectName: String = ""
    @Published var showcode: String = ""
    @Published var episode: String = ""
    @Published var day: String = ""
    @Published var unit: String = "MU"
    @Published var cgNumber: String = ""
    @Published var selectedDate: Date = Date()
    @Published var baseFolderPath: String = ""
    @Published var secondFolderPath: String = ""
    @Published var thirdFolderPath: String = ""
    @Published var selectedPreset: FolderPreset = FolderPreset.defaultPreset
    @Published var theme: ColorScheme? = nil
    @Published var createdFolderPath: String = ""
    @Published var folderStructure: [FolderItem] = []
    @Published var showFolderPreview: Bool = false
    @Published var previewFolderPath: String = ""
    @Published var previewFolderStructure: [FolderItem] = []
    @Published var showPreviewSection: Bool = false
    
    let units = ["MU", "2U", "CG", "TEST"]
    
    // Helper function to convert project name for folder use
    func projectNameForFolder() -> String {
        return projectName.replacingOccurrences(of: " ", with: "_")
    }
    
    init() {
        loadSettings()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(projectName, forKey: "projectName")
        UserDefaults.standard.set(showcode, forKey: "showcode")
        UserDefaults.standard.set(episode, forKey: "episode")
        UserDefaults.standard.set(day, forKey: "day")
        UserDefaults.standard.set(unit, forKey: "unit")
        UserDefaults.standard.set(cgNumber, forKey: "cgNumber")
        UserDefaults.standard.set(selectedDate, forKey: "selectedDate")
        UserDefaults.standard.set(baseFolderPath, forKey: "baseFolderPath")
        UserDefaults.standard.set(secondFolderPath, forKey: "secondFolderPath")
        UserDefaults.standard.set(thirdFolderPath, forKey: "thirdFolderPath")
        UserDefaults.standard.set(previewFolderPath, forKey: "previewFolderPath")
        UserDefaults.standard.set(selectedPreset.preset_name, forKey: "selectedPresetName")
        
        if let theme = theme {
            UserDefaults.standard.set(theme == .dark ? "dark" : "light", forKey: "theme")
        } else {
            UserDefaults.standard.set("system", forKey: "theme")
        }
    }
    
    func loadSettings() {
        projectName = UserDefaults.standard.string(forKey: "projectName") ?? ""
        showcode = UserDefaults.standard.string(forKey: "showcode") ?? ""
        episode = UserDefaults.standard.string(forKey: "episode") ?? ""
        day = UserDefaults.standard.string(forKey: "day") ?? ""
        unit = UserDefaults.standard.string(forKey: "unit") ?? "MU"
        cgNumber = UserDefaults.standard.string(forKey: "cgNumber") ?? ""
        baseFolderPath = UserDefaults.standard.string(forKey: "baseFolderPath") ?? ""
        secondFolderPath = UserDefaults.standard.string(forKey: "secondFolderPath") ?? ""
        thirdFolderPath = UserDefaults.standard.string(forKey: "thirdFolderPath") ?? ""
        previewFolderPath = UserDefaults.standard.string(forKey: "previewFolderPath") ?? ""
        
        if let savedDate = UserDefaults.standard.object(forKey: "selectedDate") as? Date {
            selectedDate = savedDate
        }
        
        let themeString = UserDefaults.standard.string(forKey: "theme") ?? "system"
        switch themeString {
        case "dark":
            theme = .dark
        case "light":
            theme = .light
        default:
            theme = nil
        }
    }
}

struct FolderItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: String
    let level: Int
    var children: [FolderItem] = []
}