//
//  secondFile.swift
//  bisman-cli
//
//  Created by Bisman Sahni on 4/2/25.
//





import Foundation


struct MacMuseCLI {
    static func main() async {
        print("""
        ┌────────────────────────────────────────────┐
        │                                            │
        │   👋 Welcome to MacMuse                    │
        │   Your Private On-Device RAG System 🧠     │
        │                                            │
        └────────────────────────────────────────────┘
        """)

        print("📂 Please enter the path to the folder you'd like to track:")
        guard let path = readLine(), !path.isEmpty else {
            print("⚠️ No path provided. Exiting.")
            return
        }

        print("👀 Watching folder: \(path)")
        // Start folder watcher in background
        Task.detached {
            await FolderWatcherService.startWatching(at: path)
        }

        // CLI Q&A loop
        while true {
            print("\n❓ Ask a question (or type 'exit'):", terminator: " ")
            guard let input = readLine(), !input.isEmpty else { continue }

            if input.lowercased() == "exit" {
                print("👋 Exiting MacMuse.")
                break
            }

            await LLMQuestion.run(with: input)
        }
    }
}
