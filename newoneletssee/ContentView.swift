//
//  ContentView.swift
//  newoneletssee
//
//  Created by Bisman Sahni on 4/18/25.
//




import SwiftUI
import AppKit

struct ContentView: View {
    @State private var folderPath: String = ""
    @State private var question: String = ""
    @State private var answer: String = ""
    @ObservedObject private var logManager = LogManager.shared
    @State private var watching = false
    @State private var isProcessing = false
    @State private var questionPlaceholder = "Ask a question about your files..."
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var lastLogCount: Int = 0
    
    // Colors
    let primaryColor = Color(red: 0.2, green: 0.5, blue: 0.8)
    let secondaryColor = Color(red: 0.95, green: 0.95, blue: 0.97)
    let accentColor = Color(red: 0.3, green: 0.6, blue: 0.9)
    let bgColor = Color(red: 0.98, green: 0.98, blue: 0.98)
    let logBgColor = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    var body: some View {
        HStack(spacing: 0) {
            // Main Assistant UI
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundColor(primaryColor)
                        
                        Text("MacMuse Assistant")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                    }
                    
                    Text("Your intelligent file assistant")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Folder Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("1. Select a folder to analyze")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                            
                            HStack {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(primaryColor.opacity(0.7))
                                    
                                    Text(folderPath.isEmpty ? "No folder selected" : folderPath)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .foregroundColor(folderPath.isEmpty ? Color.gray : Color.black)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(secondaryColor)
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    if let picked = openFolderPicker() {
                                        folderPath = picked
                                        Task {
                                            LogManager.shared.clear()
                                            watching = true
                                            await FolderWatcherService.startWatching(at: picked)
                                        }
                                    }
                                }) {
                                    Text("Browse")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(primaryColor)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if watching {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                        .opacity(0.8)
                                    
                                    Text("Watching folder for changes")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.gray)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Question Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("2. Ask a question about your files")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                            
                            ZStack(alignment: .topLeading) {
                                if question.isEmpty {
                                    Text(questionPlaceholder)
                                        .foregroundColor(Color.gray.opacity(0.8))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                }
                                
                                TextEditor(text: $question)
                                    .font(.system(size: 14))
                                    .padding(4)
                                    .opacity(question.isEmpty ? 0.85 : 1)
                            }
                            .frame(height: 100)
                            .background(secondaryColor)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            

                            
                            
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Generating...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                            } else {
                                Button(action: {
                                    isProcessing = true
                                    Task {
                                        await LLMQuestion.run(with: question)
                                        isProcessing = false
                                    }
                                }) {
                                    Text("Ask Question")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : accentColor)
                                        .cornerRadius(8)
                                }
                                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .buttonStyle(PlainButtonStyle())
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }

                        }
                        .padding(.horizontal, 24)
                        
                        // Answer Display
                        VStack(alignment: .leading, spacing: 12) {
                            Text("3. Response")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                            
                            ScrollView {
                                VStack(alignment: .leading) {
                                    if answer.isEmpty && !isProcessing {
                                        Text("Ask a question to see the response here")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.gray)
                                            .padding()
                                    } else {
                                        Text(answer)
                                            .font(.system(size: 14))
                                            .foregroundColor(.black)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    
                                    
                                   

                                }
                                .frame(minHeight: 160)
                            }
                            .frame(height: 200)
                            .background(secondaryColor)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
                .background(bgColor)
            }
            .frame(minWidth: 600)
            
            // Right Log Pane
            VStack(spacing: 0) {
                HStack {
                    Text("Activity Logs")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                    
                    Spacer()
                    
                    Button(action: {
                        LogManager.shared.clear()
                    }) {
                        Text("Clear")
                            .font(.system(size: 12))
                            .foregroundColor(primaryColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                Divider()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if logManager.logs.isEmpty {
                                Text("No activity logs yet")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .id("emptyLogs")
                            } else {
                                ForEach(Array(logManager.logs.enumerated()), id: \.element) { index, log in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(getLogColor(log: log))
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)
                                        
                                        Text(log)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 4)
                                    .id("log-\(index)")
                                }
                                // Invisible spacer view at the bottom for scrolling target
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottomOfLogs")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: 200)
                    }
                    .background(logBgColor)
                    .frame(maxHeight: .infinity)
                    .onChange(of: logManager.logs.count) { newCount in
                        // Only scroll if logs were added (not when cleared)
                        if newCount > lastLogCount {
                            withAnimation {
                                proxy.scrollTo("bottomOfLogs", anchor: .bottom)
                            }
                        }
                        lastLogCount = newCount
                    }
                    .onAppear {
                        scrollProxy = proxy
                        lastLogCount = logManager.logs.count
                        
                        // Initial scroll to bottom if there are logs
                        if !logManager.logs.isEmpty {
                            proxy.scrollTo("bottomOfLogs", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(width: 320)
            .background(logBgColor)
        }
        .onAppear {
            ModelLoader.preload()
            LLMQuestion.onAnswer = { result in
                answer = result
            }
        }
    }
    
    private func openFolderPicker() -> String? {
        let panel = NSOpenPanel()
        panel.title = "Select Folder to Watch"
        panel.showsResizeIndicator = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
    
    private func getLogColor(log: String) -> Color {
        if log.contains("ERROR") {
            return Color.red
        } else if log.contains("WARNING") {
            return Color.orange
        } else if log.contains("SUCCESS") {
            return Color.green
        } else {
            return Color.gray
        }
    }
}

// Preview provider for SwiftUI canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 950, height: 650)
    }
}
