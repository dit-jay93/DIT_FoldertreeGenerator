import Foundation

class PresetManager: ObservableObject {
    @Published var presets: [FolderPreset] = []
    
    init() {
        loadPresets()
    }
    
    func loadPresets() {
        presets = [FolderPreset.defaultPreset]
        
        // Try to load presets from ./Presets/ directory
        let presetsPath = "./Presets/"
        let presetsURL = URL(fileURLWithPath: presetsPath)
        
        guard FileManager.default.fileExists(atPath: presetsPath) else {
            createDefaultPresetFiles()
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: presetsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
            
            for fileURL in fileURLs {
                if let preset = loadPreset(from: fileURL) {
                    // Don't add default preset if it's already in the list
                    if preset.preset_name != "Default" {
                        presets.append(preset)
                    }
                }
            }
        } catch {
            print("Error loading presets directory: \(error)")
            createDefaultPresetFiles()
        }
    }
    
    private func loadPreset(from url: URL) -> FolderPreset? {
        do {
            let data = try Data(contentsOf: url)
            let preset = try JSONDecoder().decode(FolderPreset.self, from: data)
            return preset
        } catch {
            print("Error loading preset from \(url): \(error)")
            return nil
        }
    }
    
    private func createDefaultPresetFiles() {
        let presetsPath = "./Presets/"
        
        // Create Presets directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(
                atPath: presetsPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Error creating Presets directory: \(error)")
            return
        }
        
        // Create sample presets
        let samplePresets = [
            FolderPreset(
                preset_name: "Extended",
                folders: [
                    "Camera_Media/A_Camera",
                    "Camera_Media/B_Camera", 
                    "Camera_Media/C_Camera",
                    "Sound_Media/Boom",
                    "Sound_Media/Wireless",
                    "Reports/Camera_Reports",
                    "Reports/Sound_Reports",
                    "Reports/Script_Notes",
                    "LUTs/Show_LUTs",
                    "LUTs/Camera_LUTs",
                    "Dailies/Proxies/H264",
                    "Dailies/Proxies/ProRes_Proxy",
                    "Dailies/Graded/H264",
                    "Dailies/Graded/ProRes_422"
                ]
            ),
            FolderPreset(
                preset_name: "Minimal",
                folders: [
                    "Camera_Media",
                    "Sound_Media",
                    "Reports",
                    "Dailies"
                ]
            ),
            FolderPreset(
                preset_name: "Documentary",
                folders: [
                    "Camera_Media/A_Camera/Original",
                    "Camera_Media/A_Camera/Backup",
                    "Sound_Media/Field_Recording",
                    "Sound_Media/Interviews",
                    "Reports/Shot_Lists",
                    "Reports/Interview_Notes",
                    "LUTs",
                    "Dailies/Rough_Cut",
                    "Dailies/Interview_Selects",
                    "Archive/Raw_Footage",
                    "Archive/Audio_Files"
                ]
            )
        ]
        
        // Save sample presets to files
        for preset in samplePresets {
            let filename = "\(preset.preset_name.lowercased())_preset.json"
            let filePath = (presetsPath as NSString).appendingPathComponent(filename)
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(preset)
                try data.write(to: URL(fileURLWithPath: filePath))
            } catch {
                print("Error saving preset \(preset.preset_name): \(error)")
            }
        }
        
        // Reload presets after creating files
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadPresets()
        }
    }
}