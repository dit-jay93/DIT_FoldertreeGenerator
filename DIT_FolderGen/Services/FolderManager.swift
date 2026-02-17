import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers
import CoreText

class FolderManager: ObservableObject {
    
    func createFolderStructure(at basePath: String, with folders: [String], completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Create main folder
                try FileManager.default.createDirectory(
                    atPath: basePath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                // Create subfolders
                for folder in folders {
                    let folderPath = (basePath as NSString).appendingPathComponent(folder)
                    try FileManager.default.createDirectory(
                        atPath: folderPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                completion(true, nil)
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    func createFolderStructureAtMultipleLocations(projectName: String, folderName: String, folders: [String], locations: [String], completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var createdPaths: [String] = []
            
            for location in locations {
                guard !location.isEmpty else { continue }
                
                // Create project folder path
                let projectFolderPath = (location as NSString).appendingPathComponent(projectName)
                let fullFolderPath = (projectFolderPath as NSString).appendingPathComponent(folderName)
                
                // Check if folder exists
                if FileManager.default.fileExists(atPath: fullFolderPath) {
                    completion(false, "Folder already exists at: \(fullFolderPath)")
                    return
                }
                
                do {
                    // Create project folder
                    try FileManager.default.createDirectory(
                        atPath: projectFolderPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    
                    // Create main shooting day folder
                    try FileManager.default.createDirectory(
                        atPath: fullFolderPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    
                    // Create subfolders
                    for folder in folders {
                        let subfolderPath = (fullFolderPath as NSString).appendingPathComponent(folder)
                        try FileManager.default.createDirectory(
                            atPath: subfolderPath,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                    }
                    
                    createdPaths.append(fullFolderPath)
                } catch {
                    completion(false, error.localizedDescription)
                    return
                }
            }
            
            completion(true, nil)
        }
    }
    
    func getFolderStructure(at path: String, completion: @escaping ([FolderItem]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var structure: [FolderItem] = []
            
            // Add root folder
            let rootSize = self.calculateFolderSize(at: path)
            let rootItem = FolderItem(
                name: URL(fileURLWithPath: path).lastPathComponent,
                path: path,
                isDirectory: true,
                size: rootSize,
                level: 0
            )
            structure.append(rootItem)
            
            // Add subfolders and files
            self.addFolderContents(at: path, to: &structure, level: 1)
            
            DispatchQueue.main.async {
                completion(structure)
            }
        }
    }
    
    private func addFolderContents(at path: String, to structure: inout [FolderItem], level: Int) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            let sortedContents = contents.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            
            for item in sortedContents {
                let itemPath = (path as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory) else {
                    continue
                }
                
                let size = isDirectory.boolValue ? 
                    calculateFolderSize(at: itemPath) : 
                    calculateFileSize(at: itemPath)
                
                let folderItem = FolderItem(
                    name: item,
                    path: itemPath,
                    isDirectory: isDirectory.boolValue,
                    size: size,
                    level: level
                )
                
                structure.append(folderItem)
                
                // Recursively add contents if it's a directory
                if isDirectory.boolValue {
                    addFolderContents(at: itemPath, to: &structure, level: level + 1)
                }
            }
        } catch {
            print("Error reading directory contents at \(path): \(error)")
        }
    }
    
    private func calculateFolderSize(at path: String) -> String {
        let url = URL(fileURLWithPath: path)
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.totalFileSizeKey])
            if let size = resourceValues.totalFileSize {
                return formatFileSize(Int64(size))
            }
        } catch {
            // Fallback to manual calculation for directories
            return calculateFolderSizeManually(at: path)
        }
        
        return calculateFolderSizeManually(at: path)
    }
    
    private func calculateFolderSizeManually(at path: String) -> String {
        var totalSize: Int64 = 0
        
        let enumerator = FileManager.default.enumerator(atPath: path)
        while let file = enumerator?.nextObject() as? String {
            let filePath = (path as NSString).appendingPathComponent(file)
            
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            } catch {
                // Skip files that can't be read
                continue
            }
        }
        
        return formatFileSize(totalSize)
    }
    
    private func calculateFileSize(at path: String) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? Int64 {
                return formatFileSize(fileSize)
            }
        } catch {
            print("Error getting file size for \(path): \(error)")
        }
        
        return "0 B"
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    // MARK: - Export Functions
    
    func exportToPDF(folderStructure: [FolderItem], projectInfo: String, to url: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfDocument = PDFDocument()
            
            // Create PDF page using NSGraphicsContext
            let pageSize = CGSize(width: 612, height: 792) // Letter size
            let margin: CGFloat = 50
            let contentWidth = pageSize.width - (margin * 2)
            
            // Create a mutable data object to hold the PDF data
            let pdfData = NSMutableData()
            
            // Create a PDF graphics context
            let consumer = CGDataConsumer(data: pdfData)!
            var mediaBox = CGRect(origin: .zero, size: pageSize)
            let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
            
            context.beginPDFPage(nil)
            
            // Fill background
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            var currentY: CGFloat = pageSize.height - margin
            
            // Draw header
            let headerFont = NSFont.boldSystemFont(ofSize: 16)
            let bodyFont = NSFont.systemFont(ofSize: 10)
            let monoFont = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
            
            // Title
            let title = "DIT Folder Structure Report"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: NSColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: margin, y: currentY - titleSize.height, width: contentWidth, height: titleSize.height)
            
            context.saveGState()
            context.textMatrix = CGAffineTransform.identity
            context.translateBy(x: 0, y: pageSize.height)
            context.scaleBy(x: 1, y: -1)
            
            let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
            let ctLine = CTLineCreateWithAttributedString(attributedTitle)
            context.textPosition = CGPoint(x: margin, y: pageSize.height - currentY)
            CTLineDraw(ctLine, context)
            
            context.restoreGState()
            currentY -= titleSize.height + 20
            
            // Project info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: NSColor.black
            ]
            let infoLines = projectInfo.components(separatedBy: "\n")
            
            context.saveGState()
            context.translateBy(x: 0, y: pageSize.height)
            context.scaleBy(x: 1, y: -1)
            
            for line in infoLines {
                let lineSize = line.size(withAttributes: infoAttributes)
                let attributedLine = NSAttributedString(string: line, attributes: infoAttributes)
                let ctLine = CTLineCreateWithAttributedString(attributedLine)
                context.textPosition = CGPoint(x: margin, y: pageSize.height - currentY)
                CTLineDraw(ctLine, context)
                currentY -= lineSize.height + 5
            }
            
            currentY -= 20
            
            // Folder structure
            let structureTitle = "Folder Structure:"
            let structureTitleSize = structureTitle.size(withAttributes: titleAttributes)
            let attributedStructureTitle = NSAttributedString(string: structureTitle, attributes: titleAttributes)
            let ctStructureTitle = CTLineCreateWithAttributedString(attributedStructureTitle)
            context.textPosition = CGPoint(x: margin, y: pageSize.height - currentY)
            CTLineDraw(ctStructureTitle, context)
            currentY -= structureTitleSize.height + 15
            
            let monoAttributes: [NSAttributedString.Key: Any] = [
                .font: monoFont,
                .foregroundColor: NSColor.black
            ]
            
            for item in folderStructure {
                let prefix = self.getLevelPrefix(for: item.level)
                let icon = item.isDirectory ? "📁" : "📄"
                let line = "\(prefix)\(icon) \(item.name) (\(item.size))"
                
                let lineSize = line.size(withAttributes: monoAttributes)
                if currentY - lineSize.height < margin {
                    break // Page full
                }
                
                let attributedLine = NSAttributedString(string: line, attributes: monoAttributes)
                let ctLine = CTLineCreateWithAttributedString(attributedLine)
                context.textPosition = CGPoint(x: margin, y: pageSize.height - currentY)
                CTLineDraw(ctLine, context)
                currentY -= lineSize.height + 2
            }
            
            context.restoreGState()
            context.endPDFPage()
            context.closePDF()
            
            // Create PDFDocument from data
            if let pdfDocument = PDFDocument(data: pdfData as Data) {
                let success = pdfDocument.write(to: url)
                DispatchQueue.main.async {
                    completion(success)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func exportToCSV(folderStructure: [FolderItem], to url: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var csvContent = "Folder Name,Path,Type,Size,Level\n"
            
            for item in folderStructure {
                let type = item.isDirectory ? "Directory" : "File"
                let escapedName = self.escapeCSVField(item.name)
                let escapedPath = self.escapeCSVField(item.path)
                
                csvContent += "\(escapedName),\(escapedPath),\(type),\(item.size),\(item.level)\n"
            }
            
            do {
                try csvContent.write(to: url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Error writing CSV: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    private func getLevelPrefix(for level: Int) -> String {
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