import Foundation

/// The pure text handling behind cleanup: parsing the rules file, word swaps and tidying the model's reply.
public enum TextRules {
    /// Splits rules text into instructions for the model and the `heard → written` swaps under `## Replacements`.
    /// Only `-` or `*` list lines are swaps, so prose that mentions the arrow is skipped.
    public static func parse(_ text: String) -> (instructions: String, replacements: [(String, String)]) {
        guard let range = text.range(of: "## Replacements") else { return (text, []) }
        let replacements = text[range.upperBound...].split(separator: "\n").compactMap { line -> (String, String)? in
            let item = line.trimmingCharacters(in: .whitespaces)
            guard item.hasPrefix("-") || item.hasPrefix("*") else { return nil }
            let parts = item.components(separatedBy: "→")
            guard parts.count == 2 else { return nil }
            let heard = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: "-*` ").union(.whitespaces))
            let written = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "` ").union(.whitespaces))
            return heard.isEmpty ? nil : (heard, written)
        }
        return (String(text[..<range.lowerBound]), replacements)
    }

    public static func applyReplacements(_ text: String, _ replacements: [(String, String)]) -> String {
        replacements.reduce(text) { result, pair in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: pair.0) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return result }
            let range = NSRange(result.startIndex..., in: result)
            return regex.stringByReplacingMatches(
                in: result, range: range,
                withTemplate: NSRegularExpression.escapedTemplate(for: pair.1))
        }
    }

    /// Cleans up the model's reply, falling back to the raw transcript when the reply is empty.
    public static func tidy(_ output: String, fallback: String) -> String {
        var result = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("Output:") {
            result = String(result.dropFirst("Output:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if result.count > 1, result.hasPrefix("\""), result.hasSuffix("\""), !fallback.hasPrefix("\"") {
            result = String(result.dropFirst().dropLast())
        }
        guard let first = result.first else { return fallback }
        result = first.uppercased() + result.dropFirst()
        if let end = fallback.last, ".?!".contains(end), let last = result.last, !".?!".contains(last) {
            result.append(end)
        }
        return result
    }
}
