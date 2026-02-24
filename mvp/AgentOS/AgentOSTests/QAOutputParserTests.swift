import Testing
@testable import AgentOS

// MARK: - QAOutputParser Tests

struct QAOutputParserTests {

    // MARK: - Score Extraction

    @Test func extractScore_validFormat_returnsScore() {
        let text = """
        ## QA Review

        **Quality Score: 8/10**
        **Recommendation: APPROVE**

        ### Strengths
        - Good structure
        """
        #expect(QAOutputParser.extractScore(from: text) == 8)
    }

    @Test func extractScore_lowScore_returnsScore() {
        let text = "**Quality Score: 3/10**"
        #expect(QAOutputParser.extractScore(from: text) == 3)
    }

    @Test func extractScore_perfectScore_returnsScore() {
        let text = "**Quality Score: 10/10**"
        #expect(QAOutputParser.extractScore(from: text) == 10)
    }

    @Test func extractScore_noScore_returnsNil() {
        let text = "This output has no quality score mentioned."
        #expect(QAOutputParser.extractScore(from: text) == nil)
    }

    @Test func extractScore_malformedScore_returnsNil() {
        let text = "Quality Score: good/10"
        #expect(QAOutputParser.extractScore(from: text) == nil)
    }

    // MARK: - Recommendation Extraction

    @Test func extractRecommendation_approve() {
        let text = "**Recommendation: APPROVE**"
        #expect(QAOutputParser.extractRecommendation(from: text) == "APPROVE")
    }

    @Test func extractRecommendation_revise() {
        let text = "**Recommendation: REVISE**"
        #expect(QAOutputParser.extractRecommendation(from: text) == "REVISE")
    }

    @Test func extractRecommendation_reject() {
        let text = "**Recommendation: REJECT**"
        #expect(QAOutputParser.extractRecommendation(from: text) == "REJECT")
    }

    @Test func extractRecommendation_noRecommendation_returnsNil() {
        let text = "No recommendation here."
        #expect(QAOutputParser.extractRecommendation(from: text) == nil)
    }

    @Test func extractRecommendation_invalidValue_returnsNil() {
        let text = "Recommendation: MAYBE"
        #expect(QAOutputParser.extractRecommendation(from: text) == nil)
    }

    // MARK: - Full QA Output

    @Test func extractBoth_fullOutput_returnsCorrectValues() {
        let text = """
        ## QA Review

        **Quality Score: 7/10**
        **Recommendation: APPROVE**

        ### Strengths
        - Clear writing
        - Good structure

        ### Issues
        - Minor typos

        ### Specific Improvements Needed
        - Fix typos in paragraph 3
        """
        #expect(QAOutputParser.extractScore(from: text) == 7)
        #expect(QAOutputParser.extractRecommendation(from: text) == "APPROVE")
    }
}
