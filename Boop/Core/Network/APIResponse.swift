import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let statusCode: Int
    let message: String
    let data: T?
    let errors: [String]?
}

struct EmptyResponse: Decodable {}
