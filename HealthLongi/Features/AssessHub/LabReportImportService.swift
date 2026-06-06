import Foundation
import PDFKit
import UIKit
import Vision

/// On-device lab report import: Vision OCR for images, PDFKit for PDFs.
enum LabReportImportService {
    enum ImportError: LocalizedError {
        case noTextFound
        case pdfUnreadable

        var errorDescription: String? {
            switch self {
            case .noTextFound: "Could not read any text from this file."
            case .pdfUnreadable: "Could not open this PDF."
            }
        }
    }

    static func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw ImportError.noTextFound }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continuation.resume(throwing: ImportError.noTextFound)
                } else {
                    continuation.resume(returning: text)
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func extractText(from fileURL: URL) throws -> String {
        let ext = fileURL.pathExtension.lowercased()
        if ext == "pdf" {
            return try extractPDFText(from: fileURL)
        }
        return try extractPlainText(from: fileURL)
    }

    static func extractPlainText(from url: URL) throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let text = try String(contentsOf: url, encoding: .utf8)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ImportError.noTextFound
        }
        return text
    }

    private static func extractPDFText(from pdfURL: URL) throws -> String {
        let accessed = pdfURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { pdfURL.stopAccessingSecurityScopedResource() }
        }

        guard let document = PDFDocument(url: pdfURL) else {
            throw ImportError.pdfUnreadable
        }

        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            if let pageText = page.string, !pageText.isEmpty {
                pages.append(pageText)
            }
        }

        let text = pages.joined(separator: "\n")
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ImportError.noTextFound
        }
        return text
    }

    static func parseReportDate(from text: String) -> Date? {
        LabReportOCRService.parseReportDate(from: text)
    }

    static func parseImportedText(_ text: String) -> [LabReportOCRService.ParsedValue] {
        LabReportOCRService.parseReportText(text)
    }
}
