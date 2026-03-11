import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    case unauthorized
    case tokenExpired
    case rateLimited(retryAfter: Int?)
    case validationError(String, errors: [String]?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let detail):
            return "Failed to parse response: \(detail)"
        case .serverError(_, let message):
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
