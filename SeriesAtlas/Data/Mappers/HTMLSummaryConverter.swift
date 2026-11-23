import Foundation
import UIKit
import WebKit

@MainActor
enum HTMLSummaryConverter {
    static func plainText(from html: String?) async -> String? {
        guard let html, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        return await withCheckedContinuation { continuation in
            NSAttributedString.loadFromHTML(string: html) { attributedString, _, _ in
                let text = attributedString?.string.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: text.flatMap { $0.isEmpty ? nil : $0 })
            }
        }
    }
}
