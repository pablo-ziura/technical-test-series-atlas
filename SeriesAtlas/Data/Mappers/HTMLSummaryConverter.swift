import Foundation
import UIKit

@MainActor
enum HTMLSummaryConverter {
    static func plainText(from html: String?) -> String? {
        guard let html, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let attributedString = try? NSAttributedString(
                  data: Data(html.utf8),
                  options: [
                      .documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue,
                  ],
                  documentAttributes: nil
              ) else { return nil }

        let text = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
