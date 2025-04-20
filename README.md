# Mac-RAG (GUI Edition)

This is the GUI version of Mac-RAG — a fully on-device Retrieval-Augmented Generation (RAG) system built for macOS using SwiftUI. It enables semantic search and local document-based question answering, all inside a modern macOS desktop app interface.

## 🎥 Demo

▶️ [Watch the full demo here](https://arizonastateu-my.sharepoint.com/:v:/g/personal/bsahni_sundevils_asu_edu/ERP5-k2bmppDh5MMEpJXBloBK_eivhNDvb3t1KdBjQpv8A?e=XgUhux)

## Tech Stack

- **SwiftUI (macOS)**: Native GUI for interaction
- **CoreML**: Runs both MiniLM for embeddings and Mistral for generation
- **SQLite**: Stores chunk embeddings, metadata, and indexes
- **MiniLM (.mlpackage)**: Embedding model compiled for CoreML
- **Mistral 7B (Int4, CoreML)**: Quantized LLM for offline generation
- **FAISS**: For top-k vector similarity search

## What I Built

This macOS app lets you drop documents directly into the UI. A background service picks them up, splits them into character-based chunks, and embeds each chunk using MiniLM. These are stored with metadata in SQLite.

When a user asks a question, the query is embedded, compared against stored chunks using FAISS, and passed with the decoded context into Mistral 7B. All inference is done locally on the device — no cloud, no APIs.

## How It Works

- Built a native macOS app with SwiftUI
- Implemented a background folder watcher to auto-index new documents
- Token-aware chunking using custom Swift logic
- MiniLM embeddings generated through CoreML
- Stored embeddings and metadata in SQLite
- Used FAISS for fast similarity search
- Query + top-k chunks passed to quantized Mistral model to generate answers

## Challenges

- Managing UI state updates while background tasks run
- Converting and optimizing MiniLM and Mistral models for CoreML
- Embedding/tokenizing alignment between models and Swift
- FAISS integration in a macOS-native context
- Ensuring everything works fully offline without Ollama or server dependencies

Still a work in progress — planning to add multimodal support and deeper system-level integrations.

---
