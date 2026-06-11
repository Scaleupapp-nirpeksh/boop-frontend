import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(statusCode: Int, message: String, code: String? = nil)
    case networkError(Error)
    case unauthorized
    case tokenExpired
    case rateLimited(retryAfter: Int?)
    case validationError(String, errors: [String]?)

    /// Machine-readable error code from the backend body (e.g. "complete_setup_required").
    var code: String? {
        if case .serverError(_, _, let code) = self { return code }
        return nil
    }

    /// True when the backend signalled the requester must finish profile setup
    /// (add voice + photos) before connecting.
    var requiresSetup: Bool {
        code == "complete_setup_required"
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let detail):
            return "Failed to parse response: \(detail)"
        case .serverError(_, let message, _):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .unauthorized:
            return "Please log in again"
        case .tokenExpired:
            return "Your session has expired"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .validationError(let message, _):
            return message
        }
    }
}
