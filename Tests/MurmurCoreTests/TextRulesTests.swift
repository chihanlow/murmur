import MurmurCore
import Testing

struct ParseTests {
    @Test func splitsInstructionsFromReplacements() {
        let text = """
            # Rules
            - Remove filler words.

            ## Replacements

            Exact swaps, one per line.

            - clawed → Claude
            * `comfy UI` → `ComfyUI`
            - not a swap
            """
        let rules = TextRules.parse(text)
        #expect(rules.instructions == "# Rules\n- Remove filler words.\n\n")
        #expect(rules.replacements.map(\.0) == ["clawed", "comfy UI"])
        #expect(rules.replacements.map(\.1) == ["Claude", "ComfyUI"])
    }

    @Test func withoutReplacementsSectionKeepsWholeText() {
        let rules = TextRules.parse("- Fix punctuation.")
        #expect(rules.instructions == "- Fix punctuation.")
        #expect(rules.replacements.isEmpty)
    }

    @Test func readsOnlyListLinesAsSwaps() {
        let text = """
            ## Replacements

            Exact swaps, one per line as `heard → written`.

            - clawed → Claude
            """
        #expect(TextRules.parse(text).replacements.map(\.0) == ["clawed"])
    }

    @Test func skipsLinesWithEmptyHeardSide() {
        #expect(TextRules.parse("## Replacements\n- → Claude").replacements.isEmpty)
    }
}

struct ApplyReplacementsTests {
    @Test func ignoresCase() {
        #expect(TextRules.applyReplacements("Ask Clawed about it", [("clawed", "Claude")]) == "Ask Claude about it")
    }

    @Test func matchesWholeWordsOnly() {
        #expect(TextRules.applyReplacements("clawedback clawed", [("clawed", "Claude")]) == "clawedback Claude")
    }

    @Test func escapesSpecialCharacters() {
        #expect(TextRules.applyReplacements("I use c.d daily", [("c.d", "cd")]) == "I use cd daily")
        #expect(TextRules.applyReplacements("I use cxd daily", [("c.d", "cd")]) == "I use cxd daily")
        #expect(TextRules.applyReplacements("pay me", [("pay", "$1 \\0")]) == "$1 \\0 me")
    }
}

struct TidyTests {
    @Test func stripsLeadingOutputLabel() {
        #expect(TextRules.tidy("Output: So it went well.", fallback: "so it went well.") == "So it went well.")
    }

    @Test func capitalisesFirstLetter() {
        #expect(TextRules.tidy("so it went well", fallback: "so it went well") == "So it went well")
    }

    @Test func restoresClosingPunctuation() {
        #expect(TextRules.tidy("can you send it", fallback: "can you send it?") == "Can you send it?")
        #expect(TextRules.tidy("Done!", fallback: "done.") == "Done!")
    }

    @Test func emptyReplyFallsBackToTranscript() {
        #expect(TextRules.tidy("  Output:  ", fallback: "raw text") == "raw text")
    }
}
