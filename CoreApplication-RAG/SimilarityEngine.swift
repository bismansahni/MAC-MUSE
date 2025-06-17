//
//  SimilarityEngine.swift
//  bisman-cli
//
//  Created by Bisman Sahni on 4/2/25.
//



import Foundation
import SwiftFaiss
import SQLite

struct SimilarityEngine {
    static func findTopKMatches(for queryEmbedding: [Float], topK: Int = 4) -> [(chunk: ChunkRecord, score: Float)] {
        let records = EmbeddingDatabase.shared.getAllEmbeddings()

        var embeddings: [[Float]] = []
        var recordMap: [Int: ChunkRecord] = [:]

        for (i, record) in records.enumerated() {
            if record.embedding.count == queryEmbedding.count {
                embeddings.append(record.embedding)
                recordMap[i] = record
            } else {
                LogManager.shared.append("⚠️ Skipping \(record.file) due to dimension mismatch")
            }
        }

        guard !embeddings.isEmpty else {
            LogManager.shared.append("❌ No valid embeddings in DB")
            return []
        }

        do {
            let d = queryEmbedding.count
            let index = try FlatIndex(d: d, metricType: .l2)
            try index.add(embeddings)
            let result = try index.search([queryEmbedding], k: topK)

            return zip(result.labels[0], result.distances[0]).compactMap { (label, distance) in
                guard label >= 0, let chunk = recordMap[label] else { return nil }
                return (chunk, distance)
            }
        } catch {
            LogManager.shared.append("❌ Faiss error: \(error)")
            return []
        }
    }
}
