//
//  GPTService.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

class GPTService: ObservableObject {
    @Published var isGenerating: Bool = false
    
    // In a real app, this would be your actual API key
    private let apiKey = "your-openai-api-key"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func generateDailyInsight(mood: MoodLevel, zodiacSign: ZodiacSign, eventLabel: String? = nil, location: String? = nil) async throws -> DailyInsight {
        isGenerating = true
        defer { isGenerating = false }
        
        let prompt = createInsightPrompt(mood: mood, zodiacSign: zodiacSign, eventLabel: eventLabel, location: location)
        
        // In a real app, this would make an actual API call
        // For now, we'll simulate the response
        return try await simulateGPTResponse(prompt: prompt)
    }
    
    func generateLoveMessage(for partnerName: String, mood: MoodLevel) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }
        
        let prompt = createLoveMessagePrompt(partnerName: partnerName, mood: mood)
        
        // Simulate API call
        return try await simulateLoveMessageResponse(prompt: prompt)
    }
    
    private func createInsightPrompt(mood: MoodLevel, zodiacSign: ZodiacSign, eventLabel: String?, location: String?) -> String {
        var prompt = """
        You are a relationship coach and astrologer. Generate a brief, empathetic insight about a person's emotional state.
        
        Context:
        - Mood: \(mood.emoji) \(mood.description)
        - Zodiac Sign: \(zodiacSign.rawValue) (\(zodiacSign.element) element)
        """
        
        if let event = eventLabel {
            prompt += "\n- Recent Event: \(event)"
        }
        
        if let location = location {
            prompt += "\n- Location: \(location)"
        }
        
        prompt += """
        
        Generate:
        1. A one-sentence emotional insight (max 100 characters)
        2. A short, supportive love message (max 150 characters)
        3. Brief astrological influence (max 100 characters)
        
        Keep it warm, supportive, and relationship-focused.
        """
        
        return prompt
    }
    
    private func createLoveMessagePrompt(partnerName: String, mood: MoodLevel) -> String {
        return """
        Generate a short, loving message for \(partnerName) who is feeling \(mood.description.lowercased()) today.
        
        Requirements:
        - Maximum 100 characters
        - Include 1-2 relevant emojis
        - Be supportive and loving
        - Match the emotional tone
        
        Examples:
        - "Sending you extra hugs today! 🤗💕"
        - "You're doing amazing, love! ✨"
        - "I'm here for you always 💖"
        """
    }
    
    private func simulateGPTResponse(prompt: String) async throws -> DailyInsight {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let insights = [
            "feels calm and balanced today, needs gentle support",
            "is radiating positive energy, perfect for connection",
            "could use extra love and understanding right now",
            "is in a reflective mood, great for deep conversations",
            "needs some space but appreciates your presence"
        ]
        
        let loveMessages = [
            "Sending you a virtual hug! 🤗",
            "You're doing amazing! 💫",
            "I'm here for you always 💕",
            "You make my world brighter ✨",
            "Sending love your way 💖"
        ]
        
        let astrologicalInfluences = [
            "The moon is in a loving phase tonight 🌙",
            "Venus brings extra romance today 💫",
            "Mercury retrograde affects communication 📱",
            "Jupiter brings good fortune to relationships 🍀"
        ]
        
        return DailyInsight(
            insight: insights.randomElement() ?? "is feeling okay today",
            loveMessage: loveMessages.randomElement(),
            astrologicalInfluence: astrologicalInfluences.randomElement(),
            compatibilityScore: Int.random(in: 75...95)
        )
    }
    
    private func simulateLoveMessageResponse(prompt: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let messages = [
            "Sending you extra hugs today! 🤗💕",
            "You're doing amazing, love! ✨",
            "I'm here for you always 💖",
            "You make my world brighter 💫",
            "Sending love your way 💕",
            "You're incredible! 🌟",
            "Thinking of you! 💭💖",
            "You've got this! 💪💕"
        ]
        
        return messages.randomElement() ?? "Love you! 💖"
    }
    
    // Real API implementation (commented out for demo)
    /*
    private func makeAPIRequest(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw GPTError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GPTRequest(
            model: "gpt-3.5-turbo",
            messages: [
                GPTMessage(role: "system", content: "You are a supportive relationship coach and astrologer."),
                GPTMessage(role: "user", content: prompt)
            ],
            max_tokens: 150,
            temperature: 0.7
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GPTError.apiError
        }
        
        let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
        return gptResponse.choices.first?.message.content ?? ""
    }
    */
}

// API Models (for real implementation)
struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
    let max_tokens: Int
    let temperature: Double
}

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTResponse: Codable {
    let choices: [GPTChoice]
}

struct GPTChoice: Codable {
    let message: GPTMessage
}

enum GPTError: Error {
    case invalidURL
    case apiError
    case invalidResponse
} 