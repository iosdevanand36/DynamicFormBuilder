import Foundation

public enum ParserError: Error, LocalizedError {
    case invalidJSON(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .decodingFailed(let message):
            return "Decoding failed: \(message)"
        }
    }
}

public struct FormParseResult {
    public let form: FormDefinition
    public let warnings: [String]
}

public final class FormParser {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func parse(_ data: Data) -> Result<FormParseResult, ParserError> {
        do {
            let form = try decoder.decode(FormDefinition.self, from: data)
            return .success(FormParseResult(form: form, warnings: []))
        } catch let decodingError as DecodingError {
            return .failure(.decodingFailed(decodingError.localizedDescription))
        } catch {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }
}
