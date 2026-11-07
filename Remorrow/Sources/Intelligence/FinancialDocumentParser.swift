import Foundation

enum FinancialDocumentKind: String, CaseIterable, Identifiable {
    case receipt = "Receipt"
    case subscription = "Subscription"
    var id: String { rawValue }
}

/// Conservative on-device OCR interpretation. A purchase date is NOT a return
/// deadline, and an invoice date is NOT necessarily the next renewal.
struct FinancialDocumentSuggestion {
    var name: String
    var merchant: String
    var date: Date?
    var dateEvidence: String?
    var amount: Double?
    var sourceText: String
}

enum FinancialDocumentParser {
    static func interpret(_ raw: String, kind: FinancialDocumentKind) -> FinancialDocumentSuggestion {
        let lines = raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let merchant = lines.first(where: { line in
            line.count > 2 && line.count < 65 &&
            line.range(of: #"^(?:receipt|invoice|order|date|total|subtotal|tax|amount|thank you|www\.|https?://)"#,
                       options: [.regularExpression, .caseInsensitive]) == nil &&
            line.range(of: #"^\d{1,2}[/.-]\d{1,2}"#, options: .regularExpression) == nil
        }) ?? ""

        let triggers = kind == .receipt
            ? ["return by", "return until", "return deadline", "last day to return",
               "returns accepted until", "return window ends", "eligible until"]
            : ["next billing", "next charge", "next payment", "next renewal",
               "renews on", "renewal date", "billing date", "charged on"]

        var detectedDate: Date?
        var evidence: String?
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            for (index, line) in lines.enumerated() {
                guard triggers.contains(where: { line.localizedCaseInsensitiveContains($0) }) else { continue }
                let nearby = [line, index + 1 < lines.count ? lines[index + 1] : ""].joined(separator: " ")
                let range = NSRange(nearby.startIndex..<nearby.endIndex, in: nearby)
                if let match = detector.matches(in: nearby, range: range).first, let date = match.date {
                    detectedDate = date
                    evidence = nearby
                    break
                }
            }
        }

        var amount: Double?
        let amountRegex = try? NSRegularExpression(pattern: #"(?i)(?:grand total|total paid|amount due|total|price|charged)\s*[:$ ]*\s*\$?\s*(\d{1,6}(?:[.,]\d{2})?)"#)
        for line in lines.reversed() {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = amountRegex?.firstMatch(in: line, range: range),
               let valueRange = Range(match.range(at: 1), in: line) {
                amount = Double(line[valueRange].replacingOccurrences(of: ",", with: ""))
                break
            }
        }

        let candidateName = lines.first(where: {
            $0 != merchant && $0.count > 4 && $0.count < 65 &&
            !$0.localizedCaseInsensitiveContains("total") &&
            !$0.localizedCaseInsensitiveContains("date") &&
            !$0.localizedCaseInsensitiveContains("return") &&
            !$0.localizedCaseInsensitiveContains("renew")
        })
        let name = kind == .subscription
            ? (merchant.isEmpty ? "Subscription" : merchant + " subscription")
            : (candidateName ?? "Purchase")
        return FinancialDocumentSuggestion(name: name, merchant: merchant,
                                           date: detectedDate, dateEvidence: evidence,
                                           amount: amount, sourceText: raw)
    }
}
