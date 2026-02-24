import Testing
@testable import AgentOS

struct AgentOSTests {

    // MARK: - AgentConfig Defaults

    @Test func agentConfig_defaultCEO_usesOpus() {
        let config = AgentConfig(role: .ceo)
        #expect(config.modelIdentifier == AIModel.claudeOpus.rawValue)
        #expect(config.provider == .anthropic)
        #expect(config.temperature == 0.7)
    }

    @Test func agentConfig_defaultResearcher_usesSonnet() {
        let config = AgentConfig(role: .researcher)
        #expect(config.modelIdentifier == AIModel.claudeSonnet.rawValue)
    }

    @Test func agentConfig_providerComputedProperty_syncsWithProviderName() {
        let config = AgentConfig(role: .ceo)
        config.provider = .openai
        #expect(config.providerName == "openai")
        #expect(config.provider == .openai)
    }

    @Test func agentConfig_unknownProviderName_fallsBackToAnthropic() {
        let config = AgentConfig(role: .ceo)
        config.providerName = "unknown_provider"
        #expect(config.provider == .anthropic)
    }

    // MARK: - AIModel / AIProvider Relationships

    @Test func aiProvider_models_returnsCorrectModels() {
        let anthropicModels = AIProvider.anthropic.models
        #expect(anthropicModels.contains(.claudeOpus))
        #expect(anthropicModels.contains(.claudeSonnet))
        #expect(anthropicModels.contains(.claudeHaiku))
        #expect(!anthropicModels.contains(.gpt4o))
    }

    @Test func aiModel_provider_returnsCorrectProvider() {
        #expect(AIModel.claudeOpus.provider == .anthropic)
        #expect(AIModel.gpt4o.provider == .openai)
        #expect(AIModel.llama32.provider == .ollama)
        #expect(AIModel.deepSeekChat.provider == .deepseek)
    }
}
