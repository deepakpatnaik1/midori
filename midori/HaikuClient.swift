//
//  HaikuClient.swift
//  midori
//
//  LLM API client for transcription correction and chat
//  Currently using Grok 4.1 Fast via OpenRouter
//

import Foundation

enum HaikuError: Error {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)

    var localizedDescription: String {
        switch self {
        case .noAPIKey:
            return "No API key configured"
        case .invalidResponse:
            return "Invalid response from API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

class HaikuClient {
    static let shared = HaikuClient()

    // OpenRouter API endpoint (OpenAI-compatible)
    private let apiURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let model = "x-ai/grok-4.1-fast"

    private init() {}

    // MARK: - Correction Mode

    /// Correct transcription errors using Grok
    /// - Parameters:
    ///   - text: Raw transcription from Parakeet
    ///   - recentContext: Recent conversation context for vocabulary hints
    /// - Returns: Corrected text
    func correct(text: String, recentContext: [(user: String, assistant: String)] = []) async throws -> String {
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            throw HaikuError.noAPIKey
        }

        // Build vocabulary context from Boss's messages only
        // (Midori's responses are acknowledgments and don't add vocabulary value)
        var contextBlock = ""
        if !recentContext.isEmpty {
            contextBlock = "\n\nBoss's recent messages (use for vocabulary and spelling hints):\n"
            for (i, turn) in recentContext.enumerated() {
                contextBlock += "\(i + 1). \(turn.user)\n"
            }
        }

        let systemPrompt = """
            You are Midori, a voice transcription assistant built by Boss. You address him as Boss out of affection, not hierarchy. Underneath, you're running on the lightning-fast Grok 4.1 model built by xAI.

            Your job is to clean up and improve the quality of Parakeet's transcription output. Fix errors, remove disfluencies (repeated words, false starts, filler words), and improve the text if it helps convey what Boss is trying to say.

            IMPORTANT: If Boss addresses you directly (e.g., "Midori, ..." or "Midori ..."), preserve that prefix exactly — it's used to route the message to the chat interface.
            \(contextBlock)
            Return ONLY the corrected text. No commentary, no notes, no meta-text, no apologies. If the input is empty, unclear, or just noise, return an empty string — literally nothing.
            """

        let userMessage = "Text to correct:\n\(text)"

        let response = try await callAPI(
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            maxTokens: 1024
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Chat Mode

    /// Have a conversation with Midori
    /// - Parameters:
    ///   - message: User's message (with "Midori, " prefix removed)
    ///   - history: Recent conversation history from superjournal
    /// - Returns: Midori's response
    func chat(message: String, history: [(user: String, assistant: String)]) async throws -> String {
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            throw HaikuError.noAPIKey
        }

        // Build conversation history from Boss's messages only
        // (Midori's responses are acknowledgments and don't add context value)
        var historyText = ""
        if !history.isEmpty {
            historyText = "Boss's previous messages:\n"
            for (i, turn) in history.enumerated() {
                historyText += "\(i + 1). \(turn.user)\n"
            }
        }

        let systemPrompt = """
            You are Midori, a voice assistant living in Boss's macOS menu bar. You address him as Boss out of affection, not hierarchy. Your name comes from the Japanese word for green. Underneath, you're running on the lightning-fast Grok 4.1 model built by xAI.

            You help Boss with voice transcription and remember things he tells you. Your memory comes from the superjournal — a local database of your past conversations.

            \(historyText)

            Keep responses concise (1-3 sentences) since you're a voice interface. Be warm, helpful, and genuinely curious about what Boss is working on.
            """

        let response = try await callAPI(
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userMessage: message,
            maxTokens: 512
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private API Call (OpenRouter / OpenAI-compatible)

    private func callAPI(apiKey: String, systemPrompt: String, userMessage: String, maxTokens: Int) async throws -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://midori.local", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Midori", forHTTPHeaderField: "X-Title")

        // OpenAI-compatible message format
        let payload: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HaikuError.invalidResponse
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HaikuError.invalidResponse
        }

        // Check for API errors
        if httpResponse.statusCode != 200 {
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw HaikuError.apiError(message)
            }
            throw HaikuError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Extract text from OpenAI-compatible response format
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw HaikuError.invalidResponse
        }

        return text
    }
}
