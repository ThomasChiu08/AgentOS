import Foundation
import Testing
@testable import AgentOS

// MARK: - PipelineParser Tests

struct PipelineParserTests {

    // MARK: - JSON Extraction

    @Test func parse_validFencedJSON_returnsPipeline() {
        let text = """
        Great task! Here's my plan:
        ```json
        {
          "pipeline": [
            { "role": "researcher", "task": "Research competitors" },
            { "role": "producer", "task": "Write content" },
            { "role": "qaReviewer", "task": "Review quality" }
          ]
        }
        ```
        1. Research competitors
        2. Write content
        3. Review quality
        """
        let result = PipelineParser.parse(text)
        #expect(result != nil)
        #expect(result?.stages.count == 3)
        #expect(result?.stages[0].role == .researcher)
        #expect(result?.stages[1].role == .producer)
        #expect(result?.stages[2].role == .qaReviewer)
    }

    @Test func parse_bareBracesJSON_returnsPipeline() {
        let text = """
        Here's the plan:
        { "pipeline": [{ "role": "researcher", "task": "Look up data" }] }
        Done.
        """
        let result = PipelineParser.parse(text)
        #expect(result != nil)
        #expect(result?.stages.count == 1)
        #expect(result?.stages[0].task == "Look up data")
    }

    @Test func parse_noJSON_returnsNil() {
        let text = "This is just a conversational response with no pipeline."
        #expect(PipelineParser.parse(text) == nil)
    }

    @Test func parse_invalidJSON_returnsNil() {
        let text = """
        ```json
        { not valid json at all }
        ```
        """
        #expect(PipelineParser.parse(text) == nil)
    }

    @Test func parse_emptyPipeline_returnsNil() {
        let text = """
        ```json
        { "pipeline": [] }
        ```
        """
        #expect(PipelineParser.parse(text) == nil)
    }

    @Test func parse_moreThanSixStages_returnsNil() {
        let stages = (1...7).map { "{ \"role\": \"researcher\", \"task\": \"Task \($0)\" }" }
        let text = """
        ```json
        { "pipeline": [\(stages.joined(separator: ", "))] }
        ```
        """
        #expect(PipelineParser.parse(text) == nil)
    }

    // MARK: - Role Mapping

    @Test func parse_roleVariants_mapsCorrectly() {
        let variants: [(String, AgentRole)] = [
            ("researcher", .researcher),
            ("producer", .producer),
            ("writer", .producer),
            ("content_producer", .producer),
            ("qaReviewer", .qaReviewer),
            ("qa_reviewer", .qaReviewer),
            ("qa reviewer", .qaReviewer),
            ("reviewer", .qaReviewer),
            ("qa", .qaReviewer),
        ]

        for (roleString, expectedRole) in variants {
            let text = """
            ```json
            { "pipeline": [{ "role": "\(roleString)", "task": "Do something" }] }
            ```
            """
            let result = PipelineParser.parse(text)
            #expect(result?.stages.first?.role == expectedRole,
                    "Expected '\(roleString)' to map to \(expectedRole)")
        }
    }

    @Test func parse_unknownRole_dropsStage() {
        let text = """
        ```json
        { "pipeline": [
            { "role": "magician", "task": "Magic trick" },
            { "role": "researcher", "task": "Valid task" }
        ] }
        ```
        """
        let result = PipelineParser.parse(text)
        #expect(result?.stages.count == 1)
        #expect(result?.stages.first?.role == .researcher)
    }

    // MARK: - Research URLs

    @Test func parse_withResearchURLs_capturesURLs() {
        let text = """
        ```json
        {
          "pipeline": [{
            "role": "researcher",
            "task": "Research topic",
            "researchURLs": ["https://example.com", "https://docs.swift.org"]
          }]
        }
        ```
        """
        let result = PipelineParser.parse(text)
        #expect(result?.stages.first?.researchURLs.count == 2)
    }

    // MARK: - Build Stages

    @Test func buildStages_setsPositionAndContext() {
        let parsed = ParsedPipeline(stages: [
            ParsedStage(role: .researcher, task: "Research", researchURLs: []),
            ParsedStage(role: .producer, task: "Produce", researchURLs: []),
        ])
        let pipeline = Pipeline()
        let stages = PipelineParser.buildStages(from: parsed, pipeline: pipeline)

        #expect(stages.count == 2)
        #expect(stages[0].position == 0)
        #expect(stages[1].position == 1)
        #expect(stages[0].inputContext == "Research")
        #expect(stages[0].agentRole == .researcher)
    }

    @Test func buildStages_embedsResearchURLs() {
        let parsed = ParsedPipeline(stages: [
            ParsedStage(
                role: .researcher,
                task: "Research AI",
                researchURLs: [URL(string: "https://example.com")!]
            ),
        ])
        let pipeline = Pipeline()
        let stages = PipelineParser.buildStages(from: parsed, pipeline: pipeline)

        #expect(stages[0].inputContext.contains("https://example.com"))
        #expect(stages[0].inputContext.contains("Research AI"))
    }
}
