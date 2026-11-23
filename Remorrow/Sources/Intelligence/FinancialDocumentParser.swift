import Foundation

enum FinancialDocumentKind: String, CaseIterable, Identifiable {
    case receipt = "Receipt"
    case subscription = "Subscription"
    var id: String { rawValue }
}

/// OCR proposes editable details; it must never convert a purchase date into a
/// verified return deadline or an invoice date into a confirmed renewal.
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
    var nameCandidates: [String] = []
    var currencyCode: String? = nil
}

enum FinancialDocumentParser {
    static func interpret(_ raw: String, kind: FinancialDocumentKind) -> FinancialDocumentSuggestion {
        let lines = raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let merchant = labeledIdentity(in: lines, pattern:
            #"(?i)^(?:merchant|sold by|retailer|store name|provider|seller)\s*[:\-]\s*(.+)$"#)
            ?? lines.prefix(8).first(where: isLikelyMerchant) ?? ""

        let explicitName = labeledIdentity(in: lines, pattern:
            #"(?i)^(?:item(?: name)?|product(?: name)?|description|service(?: name)?|plan(?: name)?|subscription(?: name)?)\s*[:\-]\s*(.+)$"#)

        // OCR frequently starts with a store header, then has receipts, dates,
        // total lines, etc. Treat product candidates separately from merchants.
        let candidates = lines.map(strippingTrailingPrice)
            .filter { $0.caseInsensitiveCompare(merchant) != .orderedSame && isLikelyProduct($0) }
        let suggestedName: String
        if let explicitName, isLikelyProduct(explicitName) {
            suggestedName = explicitName
        } else if kind == .subscription {
            // Avoid inventing a "Merchant subscription" product that may not exist.
            suggestedName = merchant.isEmpty ? (candidates.first ?? "Subscription") : merchant
        } else {
            suggestedName = candidates.first ?? "Purchase"
        }

        let dateTriggers = kind == .receipt
            ? ["return by", "return until", "return deadline", "last day to return",
               "returns accepted until", "return window ends", "eligible until"]
            : ["next billing", "next charge", "next payment", "next renewal",
               "renews on", "renewal date", "billing date", "charged on"]
        let foundDate = labeledDateWithEvidence(in: lines, labels: dateTriggers)

        // Subtotal, tax and item prices are NOT the grand total. Evaluate
        // stronger total labels before using weaker labels.
        let amountLabels = [
            "grand total", "total paid", "amount paid", "order total", "total due",
            "amount due", "total", "charged", "price"
        ]
        var amount: Double?
        var matchedAmountLine: String?
        for label in amountLabels {
            if let line = lines.first(where: { monetaryAmount(in: $0, label: label) != nil }) {
                amount = monetaryAmount(in: line, label: label)
                matchedAmountLine = line
                break
            }
        }

        let purchaseDate: Date? = kind == .receipt
            ? labeledDate(in: lines, labels: [
                "purchased on", "purchased:", "purchase date", "order date", "date of purchase"
            ]) : nil
        let warranty = kind == .receipt
            ? labeledDateWithEvidence(in: lines, labels: [
                "warranty expires", "warranty expiration", "warranty until",
                "warranty ends", "covered until", "coverage expires", "warranty valid until"
            ]) : nil
        let receiptNumber = kind == .receipt
            ? captureFirst(raw, pattern:
                #"(?im)\b(?:receipt|order|invoice)\s*(?:no\.?|number|#|id)\s*[:#-]?\s*([A-Z0-9-]{4,30})\b"#)
            : nil
        return FinancialDocumentSuggestion(
            name: suggestedName, merchant: merchant,
            date: foundDate?.0, dateEvidence: foundDate?.1,
            amount: amount, purchaseDate: purchaseDate,
            warrantyExpiry: warranty?.0, warrantyEvidence: warranty?.1,
            receiptNumber: receiptNumber, sourceText: raw,
            nameCandidates: Array(([suggestedName] + candidates).filter {
                $0 != "Purchase" && $0 != "Subscription"
            }.reduce(into: [String]()) { unique, value in
                if !unique.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
                    unique.append(value)
                }
            }.prefix(6)),
            currencyCode: matchedAmountLine.flatMap(currencyCodeFromAmountLine)
        )
    }

    private static func labeledIdentity(in lines: [String], pattern: String) -> String? {
        for line in lines {
            guard let value = captureFirst(line, pattern: pattern) else { continue }
            let trimmed = strippingTrailingPrice(value)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func strippingTrailingPrice(_ input: String) -> String {
        input.replacingOccurrences(
            of: #"\s+(?:(?:[$€£]|USD|EUR|GBP)\s*)?\d{1,7}(?:[.,]\d{3})*(?:[.,]\d{2})?\s*$"#,
            with: "", options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isLikelyMerchant(_ input: String) -> Bool {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (3...64).contains(value.count), value.rangeOfCharacter(from: .letters) != nil,
              !value.contains("$"), !value.contains("@"),
              !value.lowercased().hasPrefix("http"),
              !value.lowercased().hasPrefix("www.") else { return false }
        let excluded = ["receipt", "invoice", "order", "date", "subtotal",
                        "total", "grand total", "tax", "thank", "payment", "bill to", "sold to",
                        "item", "product", "description", "charged", "amount",
                        "transaction", "return", "purchase", "subscription", "qty"]
        return !excluded.contains(where: { value.lowercased().hasPrefix($0) })
    }

    private static func isLikelyProduct(_ value: String) -> Bool {
        guard (3...90).contains(value.count),
              value.rangeOfCharacter(from: .letters) != nil,
              value.range(of: #"^\d"#, options: .regularExpression) == nil else { return false }
        let lower = value.lowercased()
        let excluded = [
            "receipt", "invoice", "order", "date", "subtotal", "total",
            "grand total", "order total", "total paid", "amount paid",
            "tax", "discount", "shipping", "payment", "visa", "mastercard",
            "change", "cash", "credit", "debit", "thank", "balance",
            "authorization", "terminal", "transaction", "bill to", "sold by",
            "return", "warranty", "www.", "http", "contact", "phone",
            "customer", "purchased", "amount", "renew", "next billing",
            "billing date", "qty", "quantity", "item description",
            "merchant:", "seller:", "provider:", "store name:",
            "card ending", "payment method", "ref no", "invoice number", "receipt number"
        ]
        return !excluded.contains(where: { lower.hasPrefix($0) })
    }

    private static func monetaryAmount(in input: String, label: String) -> Double? {
        let escapedLabel = NSRegularExpression.escapedPattern(for: label)
        let regexPattern = #"(?i)^\s*"# + escapedLabel +
            #"\s*[:\-]?\s*(?:(?:USD|EUR|GBP|CAD|AUD)\s*)?(?:[$€£]\s*)?([0-9][0-9.,]{0,15})\s*(?:USD|EUR|GBP|CAD|AUD)?\s*$"#
        guard let capture = captureFirst(input, pattern: regexPattern) else { return nil }
        return normalizedAmount(capture)
    }

    /// OCR from both US (1,299.99) and European (1.299,99) receipts.
    /// Reject ambiguous or malformed amounts rather than silently guessing.
    private static func normalizedAmount(_ input: String) -> Double? {
        let lastComma = input.lastIndex(of: ",")
        let lastPeriod = input.lastIndex(of: ".")
        var normalized = input
        if let comma = lastComma, let period = lastPeriod {
            if comma > period {
                normalized = normalized.replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = normalized.replacingOccurrences(of: ",", with: "")
            }
        } else if let comma = lastComma {
            let suffix = input[input.index(after: comma)...]
            normalized = suffix.count == 3
                ? input.replacingOccurrences(of: ",", with: "")
                : input.replacingOccurrences(of: ",", with: ".")
        } else if let period = lastPeriod {
            let suffix = input[input.index(after: period)...]
            if suffix.count == 3 {
                normalized = input.replacingOccurrences(of: ".", with: "")
            }
        }
        guard let parsed = Double(normalized), parsed.isFinite, parsed >= 0 else { return nil }
        return parsed
    }

    private static func currencyCodeFromAmountLine(_ line: String) -> String? {
        if line.contains("€") { return "EUR" }
        if line.contains("£") { return "GBP" }
        let upper = line.uppercased()
        for currency in ["USD", "EUR", "GBP", "CAD", "AUD"] {
            if upper.range(of: #"\b"# + currency + #"\b"#,
                           options: .regularExpression) != nil { return currency }
        }
        // A bare dollar sign is ambiguous across several currencies.
        return nil
    }

    private static func labeledDate(in lines: [String], labels: [String]) -> Date? {
        labeledDateWithEvidence(in: lines, labels: labels)?.0
    }

    private static func labeledDateWithEvidence(in lines: [String], labels: [String]) -> (Date, String)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        for (index, line) in lines.enumerated() {
            guard labels.contains(where: { line.localizedCaseInsensitiveContains($0) }) else { continue }
            let candidate = line + " " + (index + 1 < lines.count ? lines[index + 1] : "")
            let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
            for match in detector.matches(in: candidate, range: range) {
                guard let date = match.date,
                      let matchedRange = Range(match.range, in: candidate),
                      String(candidate[matchedRange]).range(of: #"\d"#, options: .regularExpression) != nil else {
                    continue
                }
                return (date, candidate)
            }
        }
        return nil
    }

    private static func captureFirst(_ input: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..<input.endIndex, in: input)),
              let range = Range(match.range(at: 1), in: input) else { return nil }
        return String(input[range])
    }
}
