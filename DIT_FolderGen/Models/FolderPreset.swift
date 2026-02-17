import Foundation

struct FolderPreset: Codable, Identifiable, Hashable {
    let id = UUID()
    let preset_name: String
    let folders: [String]
    
    private enum CodingKeys: String, CodingKey {
        case preset_name, folders
    }
    
    static let defaultPreset = FolderPreset(
        preset_name: "Default",
        folders: [
            "Camera_Media",
            "Sound_Media", 
            "Reports",
            "LUTs",
            "Dailies/Proxies",
            "Dailies/H264"
        ]
    )
}