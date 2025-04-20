
import Foundation
import CoreML
import Models
import Generation
import SQLite

struct LLMQuestion {
    @MainActor static var onAnswer: ((String) -> Void)? = nil

    static func run(with question: String) async {
        // 1. Get question embedding
        guard let queryEmbedding = await MiniLMEmbedderForQuestion.embed(question: question) else {
            LogManager.shared.append("❌ Failed to embed question.")
            return
        }

        // 2. Find top matches using vector similarity
        let matches = SimilarityEngine.findTopKMatches(for: queryEmbedding)

        // 3. Build context from matches
        var context = ""
        var seenChunks = Set<String>()
        var sourceFiles = Set<String>()

        for (chunk, _) in matches {
            let shortName = URL(fileURLWithPath: chunk.file).lastPathComponent
            sourceFiles.insert(shortName)

            if seenChunks.insert(chunk.text).inserted {
                context += "\n--- From: \(shortName)\n\(chunk.text)\n"
            }
        }

        let sourceSummary = sourceFiles.joined(separator: ", ")
        LogManager.shared.append("🧾 Context from files: \(sourceSummary)")

        let prompt = """
        You are an intelligent assistant that answers questions based solely on the provided context. 
        Do not use prior knowledge. If the answer is not present in the context, say no such file with the provided question context exists.

        Context:
        \(context)

        Question:
        \(question)

        Answer:
        """

        LogManager.shared.append("📝 Prompt:\n\(prompt)")
        LogManager.shared.append("🔢 Token estimate: \(prompt.split { $0.isWhitespace || $0.isNewline }.count)")

        let config = GenerationConfig(
            maxNewTokens: 400,
            temperature: 0.7,
            topK: 50,
            topP: 0.95
        )

        guard let model = try? await ModelLoader.load() else {
            LogManager.shared.append("❌ Failed to load Mistral model.")
            return
        }

        do {
            let rawOutput = try await model.generate(config: config, prompt: prompt)

            // ✅ Extract only the part after "Answer:"
            let output: String
            if let range = rawOutput.range(of: "Answer:") {
                output = rawOutput[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                output = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            await MainActor.run {
                LogManager.shared.append("✅ Response:")
                LogManager.shared.append(output)
                LogManager.shared.append("📁 Sources: \(sourceSummary)")
                onAnswer?("\(output)\n\n📁 Sources: \(sourceSummary)")
            }
        } catch {
            LogManager.shared.append("❌ Generation failed: \(error)")
            await MainActor.run {
                LogManager.shared.append("❌ Error: \(error.localizedDescription)")
            }
        }
    }
}
