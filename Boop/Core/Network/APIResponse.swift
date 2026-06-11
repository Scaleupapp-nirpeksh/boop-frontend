import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let statusCode: Int
    let message: String
    let data: T?
    let errors: [String]?
    /// Machine-readable error code from the backend (e.g. "complete_setup_required").
    let code: String?
}

struct EmptyResponse: Decodable {}
