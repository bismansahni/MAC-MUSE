//
//

//


import Foundation
import PDFKit

class FolderWatcherService {
    private static var previousFiles: Set<String> = []

    static func startWatching(at folderPath: String) async {
        let fileManager = FileManager.default
        let folderURL = URL(fileURLWithPath: folderPath)

        guard fileManager.fileExists(atPath: folderPath) else {
            LogManager.shared.append("❌ Folder does not exist at path: \(folderPath)")
            return
        }

        LogManager.shared.append("✅ Started watching folder: \(folderPath)")

        // Initial snapshot of all files
        previousFiles = getAllFiles(in: folderURL)

        // Open the folder for monitoring file system events
        let fileDescriptor = open(folderPath, O_EVTONLY)
        guard fileDescriptor != -1 else {
            LogManager.shared.append("❌ Failed to open folder for monitoring.")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .extend, .attrib, .rename],
            queue: DispatchQueue.global()
        )

        source.setEventHandler {
            let currentFiles = getAllFiles(in: folderURL)
            let added = currentFiles.subtracting(previousFiles)
            let removed = previousFiles.subtracting(currentFiles)

            // Handle added files (trigger embedding)
            for file in added {
                LogManager.shared.append("➕ Added: \(file)")
                Task {
                    do {
                        let fileURL = URL(fileURLWithPath: file)
                        let content: String

                        if fileURL.pathExtension.lowercased() == "pdf" {
                            content = extractTextFromPDF(at: fileURL)
                            LogManager.shared.append("📄 Extracted PDF text length: \(content.count)")
                               print("📄 PDF content preview: \(content.prefix(200))")
                        } else {
                            content = try String(contentsOf: fileURL, encoding: .utf8)
                        }

                        await MiniLMEmbedder.embed(text: content, filePath: file)
                    } catch {
                        LogManager.shared.append("❌ Failed to read file: \(file)\nError: \(error)")
                    }
                }
            }

            // Handle removed files (trigger removal from index if needed)
            for file in removed {
                LogManager.shared.append("❌ Removed: \(file)")
                // Optional: trigger removal from similarity index
            }

            previousFiles = currentFiles
        }

        source.setCancelHandler {
            close(fileDescriptor)
        }

        source.resume()

        // Keep alive
        while true {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private static func getAllFiles(in directory: URL) -> Set<String> {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }

        var files = Set<String>()
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if ["pdf", "txt", "md"].contains(ext) {
                files.insert(fileURL.path)
            }
        }
        return files
    }

    private static func extractTextFromPDF(at url: URL) -> String {
        guard let pdfDoc = PDFDocument(url: url) else {
            LogManager.shared.append("❌ Failed to open PDF: \(url.lastPathComponent)")
            return ""
        }

        var fullText = ""
        for i in 0..<pdfDoc.pageCount {
            if let page = pdfDoc.page(at: i),
               let text = page.string {
                fullText += text + "\n"
            }
        }

        if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            LogManager.shared.append("⚠️ PDF appears to have no extractable text: \(url.lastPathComponent)")
        }

        return fullText
    }
}
