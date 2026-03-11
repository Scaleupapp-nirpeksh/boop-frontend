import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL = "http://35.154.171.1/api/v1"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatters: [DateFormatter] = {
                let iso = DateFormatter()
                iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                let isoNoMs = DateFormatter()
                isoNoMs.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let dateOnly = DateFormatter()
                dateOnly.dateFormat = "yyyy-MM-dd"
                return [iso, isoNoMs, dateOnly]
            }()

            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - JSON Requests

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try await buildRequest(for: endpoint)
        return try await execute(urlRequest)
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let urlRequest = try await buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            let refreshed = await AuthManager.shared.refreshTokenIfNeeded()
            if refreshed {
                var retryRequest = urlRequest
                if let newToken = await AuthManager.shared.accessToken {
                    retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                }
                let (retryData, retryResponse) = try await session.data(for: retryRequest)
                guard let retryHTTP = retryResponse as? HTTPURLResponse, retryHTTP.statusCode < 400 else {
                    throw APIError.serverError(statusCode: (retryResponse as? HTTPURLResponse)?.statusCode ?? 500, message: "Request failed")
                }
                return
            } else {
                await AuthManager.shared.logout()
                throw APIError.unauthorized
            }
        }

        guard httpResponse.statusCode < 400 else {
            // Try to parse error message
            if let apiResponse = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data) {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: apiResponse.message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Request failed")
        }
    }

    // MARK: - Multipart Requests

    func uploadVoiceIntro(data: Data, duration: Int) async throws -> User {
        var formData = MultipartFormData()
        formData.addFile(name: "voiceIntro", filename: "voice_intro.m4a", mimeType: "audio/m4a", fileData: data)
        formData.addField(name: "duration", value: "\(duration)")

        var urlRequest = try await buildRequest(for: .uploadVoiceIntro)
        urlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = formData.finalize()

        let wrapper: UserWrapper = try await execute(urlRequest)
        return wrapper.user
    }

    func uploadVoiceAnswer(audioData: Data, questionNumber: Int) async throws -> SubmitAnswerResponse {
        var formData = MultipartFormData()
        formData.addFile(name: "voiceAnswer", filename: "voice_answer.m4a", mimeType: "audio/m4a", fileData: audioData)
        formData.addField(name: "questionNumber", value: "\(questionNumber)")

        var urlRequest = try await buildRequest(for: .submitVoiceAnswer)
        urlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = formData.finalize()

        return try await execute(urlRequest)
    }

    func uploadPhotos(images: [Data]) async throws -> User {
        var formData = MultipartFormData()
        for (index, imageData) in images.enumerated() {
            formData.addFile(
                name: "photos",
                filename: "photo_\(index).jpg",
                mimeType: "image/jpeg",
                fileData: imageData
            )
        }

        var urlRequest = try await buildRequest(for: .uploadPhotos)
        urlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = formData.finalize()

        let wrapper: UserWrapper = try await execute(urlRequest)
        return wrapper.user
    }

    func uploadConversationMedia(
        data: Data,
        conversationId: String,
        mediaType: String,
        fileName: String,
        mimeType: String,
        duration: Double? = nil
    ) async throws -> UploadedConversationMediaResponse {
        var formData = MultipartFormData()
        formData.addFile(name: "file", filename: fileName, mimeType: mimeType, fileData: data)
        formData.addField(name: "type", value: mediaType)
        if let duration {
            formData.addField(name: "duration", value: String(duration))
        }

        var urlRequest = try await buildRequest(for: .uploadConversationMedia(conversationId: conversationId))
        urlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = formData.finalize()

        return try await execute(urlRequest)
    }

    // MARK: - Private

    private func buildRequest(for endpoint: APIEndpoint) async throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if endpoint.requiresAuth {
            let token = await AuthManager.shared.accessToken
            if let token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        // Handle 401 — attempt token refresh
        if httpResponse.statusCode == 401 {
            let refreshed = await AuthManager.shared.refreshTokenIfNeeded()
            if refreshed {
                // Retry with new token
                var retryRequest = request
                if let newToken = await AuthManager.shared.accessToken {
                    retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                }
                let (retryData, retryResponse) = try await session.data(for: retryRequest)
                guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                    throw APIError.networkError(URLError(.badServerResponse))
                }
                return try parseResponse(data: retryData, statusCode: retryHTTP.statusCode)
            } else {
                await AuthManager.shared.logout()
                throw APIError.unauthorized
            }
        }

        return try parseResponse(data: data, statusCode: httpResponse.statusCode)
    }

    private func parseResponse<T: Decodable>(data: Data, statusCode: Int) throws -> T {
        if statusCode == 429 {
            throw APIError.rateLimited(retryAfter: nil)
        }

        let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)

        guard apiResponse.success, let responseData = apiResponse.data else {
            if statusCode == 422 || statusCode == 400 {
                throw APIError.validationError(apiResponse.message, errors: apiResponse.errors)
            }
            throw APIError.serverError(statusCode: statusCode, message: apiResponse.message)
        }

        return responseData
    }
}

// Type-erased Encodable wrapper
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
