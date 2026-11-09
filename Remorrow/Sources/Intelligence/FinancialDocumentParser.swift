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
    var purchaseDate: Date?
    var warrantyExpiry: Date?
    var warrantyEvidence: String?
    var receiptNumber: String?
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
        let purchaseDate: Date? = kind == .receipt
            ? labeledDate(in: lines, labels: ["purchased on", "purchase date", "order date", "date of purchase"])
            : nil
        let warrantyLine = kind == .receipt
            ? labeledDateWithEvidence(in: lines, labels: [
                "warranty expires", "warranty expiration", "warranty until",
                "warranty ends", "covered until", "coverage expires", "warranty valid until"
            ]) : nil
        let receiptNumber = kind == .receipt
            ? captureFirst(raw, pattern: #"(?im)\b(?:receipt|order|invoice)\s*(?:no\.?|number|#|id)\s*[:#-]?\s*([A-Z0-9-]{4,30})\b"#)
            : nil
        let name = kind == .subscription
            ? (merchant.isEmpty ? "Subscription" : merchant + " subscription")
            : (candidateName ?? "Purchase")
        return FinancialDocumentSuggestion(name: name, merchant: merchant,
                                           date: detectedDate, dateEvidence: evidence,
                                           amount: amount,
                                           purchaseDate: purchaseDate,
                                           warrantyExpiry: warrantyLine?.0,
                                           warrantyEvidence: warrantyLine?.1,
                                           receiptNumber: receiptNumber,
                                           sourceText: raw)
    }
    private static func labeledDate(in lines: [String], labels: [String]) -> Date? {
        labeledDateWithEvidence(in: lines, labels: labels)?.0
    }

    private static func labeledDateWithEvidence(in lines: [String], labels: [String]) -> (Date, String)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        for (i, line) in lines.enumerated() {
            guard labels.contains(where: { line.localizedCaseInsensitiveContains($0) }) else { continue }
            let candidate = line + " " + (i + 1 < lines.count ? lines[i + 1] : "")
            let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
            for result in detector.matches(in: candidate, options: [], range: range) {
                guard let date = result.date,
                      let matchRange = Range(result.range, in: candidate),
                      String(candidate[matchRange]).range(of: #"\d"#, options: .regularExpression) != nil else { continue }
                return (date, candidate)
            }
        }
        return nil
    }

    private static func captureFirst(_ input: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: input, range: NSRange(input.startIndex..<input.endIndex, in: input)),
              let valueRange = Range(result.range(at: 1), in: input) else { return nil }
        return String(input[valueRange])
    }

}
