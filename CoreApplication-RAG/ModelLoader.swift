//
//  ModelLoader.swift
//  bisman-cli
//
//  Created by Bisman Sahni on 4/2/25.






import CoreML
import Models

class ModelLoader {
    static private var cachedModel: LanguageModel?

    static func preload() {
        if cachedModel != nil { return }

        print("📦 [ModelLoader] Preloading model from bundle...")

        guard let modelURL = Bundle.main.url(forResource: "StatefulMistral7BInstructInt4", withExtension: "mlmodelc") else {
            print("❌ [ModelLoader] .mlmodelc not found")
            return
        }

        do {
            cachedModel = try LanguageModel.loadCompiled(url: modelURL, computeUnits: .cpuAndGPU)
            print("✅ [ModelLoader] Model preloaded and ready")
        } catch {
            print("❌ [ModelLoader] Failed to load: \(error.localizedDescription)")
        }
    }

    static func load() throws -> LanguageModel {
        guard let model = cachedModel else {
            throw NSError(domain: "Model not preloaded", code: 1)
        }
        return model
    }
}
