//
//  GenerateEmbedding.swift
//  bisman-cli
//
//  Created by Bisman Sahni on 4/2/25.
//
//
//
//
//





import CoreML
import Path
import Models
import Tokenizers
import Foundation
import SQLite

struct MiniLMEmbedder {
    static func embed(text inputText: String, filePath: String) async {
        LogManager.shared.append("✅ Starting embedding for file: \(filePath)")

        do {
            // Load vocab
//            let vocabPath = "/Users/bismansahni/Documents/bisman-cli/bisman-cli/vocab.txt"
            
            guard let vocabPath = Bundle.main.path(forResource: "vocab", ofType: "txt") else {
                LogManager.shared.append("❌ Failed to find vocab.txt in bundle.")
                return
            }

//            let vocabContent = try String(contentsOfFile: vocabPath, encoding: .utf8)
            let vocabContent = try String(contentsOf: URL(fileURLWithPath: vocabPath.string), encoding: .utf8)

            let tokens = vocabContent.split(separator: "\n").map(String.init)
            var vocab: [String: Int] = [:]
            for (i, token) in tokens.enumerated() {
                vocab[token] = i
            }

            // Tokenize & optionally chunk
            let tokenizer = BertTokenizer(vocab: vocab, merges: nil)
            let tokenList = tokenizer.tokenize(text: inputText).filter { $0 != "[UNK]" }
            let chunkSize = 128
            let chunks = tokenList.chunked(into: chunkSize)

            for (index, chunk) in chunks.enumerated() {
                let inputIds = chunk.map { vocab[$0] ?? vocab["[UNK]"]! }
                let attentionMask = Array(repeating: 1, count: inputIds.count)

                let inputArray = try MLMultiArray(shape: [1, NSNumber(value: inputIds.count)], dataType: .int32)
                let attentionArray = try MLMultiArray(shape: [1, NSNumber(value: attentionMask.count)], dataType: .int32)
                for (i, id) in inputIds.enumerated() {
                    inputArray[[0, i] as [NSNumber]] = NSNumber(value: id)
                }
                for (i, mask) in attentionMask.enumerated() {
                    attentionArray[[0, i] as [NSNumber]] = NSNumber(value: mask)
                }

                guard let modelUrl = Bundle.main.url(forResource: "minilm", withExtension: "mlmodelc") else {
                    LogManager.shared.append("❌ Failed to find minilm.mlpackage in bundle.")
                    return
                }
                


                let model = try MLModel(contentsOf: modelUrl)


                // Predict
                let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
                    "input_ids": inputArray,
                    "attention_mask": attentionArray
                ])
                let prediction = try await model.prediction(from: inputFeatures)

                if let embedding = prediction.featureValue(for: "pooler_output")?.multiArrayValue {
                    let floatArray = (0..<embedding.count).map { Float(truncating: embedding[$0]) }

                    let chunkText = decodeWordPieceTokens(chunk)

                    EmbeddingDatabase.shared.insertChunk(file: filePath, chunkIndex: index, text: chunkText, embedding: floatArray)
                    LogManager.shared.append("💾 Inserted chunk \(index) for \(filePath)")
                    
                    
                 

                }
            }
        } catch {
            LogManager.shared.append("❌ Error embedding \(filePath): \(error)")
        }
    }

    private static func decodeWordPieceTokens(_ tokens: [String]) -> String {
        var tokenList: [String] = []
        var currentToken = ""

        for token in tokens {
            if token.starts(with: "##") {
                currentToken += String(token.dropFirst(2))
            } else {
                if !currentToken.isEmpty {
                    tokenList.append(currentToken)
                }
                currentToken = token
            }
        }

        if !currentToken.isEmpty {
            tokenList.append(currentToken)
        }

        return tokenList.joined(separator: " ")
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
