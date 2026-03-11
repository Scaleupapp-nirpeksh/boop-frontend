import Foundation
import SocketIO

@Observable
final class RealtimeService {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error
    }

    static let shared = RealtimeService()

    private(set) var isConnected = false
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var lastErrorMessage: String?
    private(set) var lastConnectedAt: Date?

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentToken: String?

    private init() {}

    func connect(token: String?) {
        guard let token, !token.isEmpty else { return }
        if currentToken == token, isConnected { return }

        disconnect()
        currentToken = token
        updateConnectionState(.connecting)
        lastErrorMessage = nil

        guard let url = URL(string: "http://35.154.171.1") else { return }

        let manager = SocketManager(
            socketURL: url,
            config: [
                .log(false),
                .compress,
                .forceWebsockets(true),
                .reconnects(true),
                .connectParams(["token": token])
            ]
        )
        let socket = manager.defaultSocket
        self.manager = manager
        self.socket = socket

        registerCoreHandlers(on: socket)
        registerEventHandlers(on: socket)
        socket.connect()
    }

    func disconnect() {
        currentToken = nil
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil
        isConnected = false
        updateConnectionState(.disconnected)
    }

    func reconnectIfPossible() async {
        let token = currentToken ?? AuthManager.shared.accessToken
        connect(token: token)
    }

    func emitTypingStart(conversationId: String) {
        socket?.emit("typing:start", ["conversationId": conversationId])
    }

    func emitTypingStop(conversationId: String) {
        socket?.emit("typing:stop", ["conversationId": conversationId])
    }

    private func registerCoreHandlers(on socket: SocketIOClient) {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.isConnected = true
            self?.lastConnectedAt = Date()
            self?.lastErrorMessage = nil
            self?.updateConnectionState(.connected)
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.isConnected = false
            self?.updateConnectionState(self?.currentToken == nil ? .disconnected : .reconnecting)
        }

        socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            self?.updateConnectionState(.reconnecting)
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            let errorText = (data.first as? String) ?? "Live updates unavailable."
            NotificationCenter.default.post(
                name: .realtimeError,
                object: nil,
                userInfo: ["payload": data.first as Any]
            )
            DispatchQueue.main.async {
                self?.lastErrorMessage = errorText
                self?.updateConnectionState(.error)
            }
        }

        socket.on(clientEvent: .statusChange) { [weak self] data, _ in
            guard let rawStatus = data.first as? String else { return }
            switch rawStatus.lowercased() {
            case "connected":
                self?.updateConnectionState(.connected)
            case "connecting":
                self?.updateConnectionState(.connecting)
            case "disconnected", "notconnected":
                self?.updateConnectionState(self?.currentToken == nil ? .disconnected : .reconnecting)
            default:
                break
            }
        }
    }

    private func updateConnectionState(_ state: ConnectionState) {
        connectionState = state
        NotificationCenter.default.post(name: .realtimeStatusChanged, object: nil)
    }

    var statusTitle: String {
        switch connectionState {
        case .connected:
            return "Live"
        case .connecting:
            return "Connecting"
        case .reconnecting:
            return "Reconnecting"
        case .error:
            return "Offline"
        case .disconnected:
            return "Disconnected"
        }
    }

    var statusMessage: String {
        switch connectionState {
        case .connected:
            return "Messages and match updates are live."
        case .connecting:
            return "Joining live updates."
        case .reconnecting:
            return "Trying to restore the live connection."
        case .error:
            return lastErrorMessage ?? "Live updates are temporarily unavailable."
        case .disconnected:
            return "Live updates are turned off."
        }
    }

    var shouldShowBanner: Bool {
        connectionState != .connected && currentToken != nil
    }

    var statusColorHex: String {
        switch connectionState {
        case .connected:
            return "DDF5E8"
        case .connecting:
            return "EEF4FA"
        case .reconnecting:
            return "FFF3DE"
        case .error, .disconnected:
            return "FCE8E6"
        }
    }

    var statusAccentHex: String {
        switch connectionState {
        case .connected:
            return "1F8A5B"
        case .connecting:
            return "376A90"
        case .reconnecting:
            return "C17A16"
        case .error, .disconnected:
            return "C95044"
        }
    }

    private func registerEventHandlers(on socket: SocketIOClient) {
        socket.on("message:new") { [weak self] data, _ in
            self?.postDecoded(ChatMessage.self, name: .realtimeMessageNew, from: data)
        }
        socket.on("message:reaction") { [weak self] data, _ in
            self?.postDecoded(MessageReactionEvent.self, name: .realtimeMessageReaction, from: data)
        }
        socket.on("message:read") { [weak self] data, _ in
            self?.postDecoded(MessageReadEvent.self, name: .realtimeMessageRead, from: data)
        }
        socket.on("typing:start") { [weak self] data, _ in
            self?.postDecoded(TypingEvent.self, name: .realtimeTypingStart, from: data)
        }
        socket.on("typing:stop") { [weak self] data, _ in
            self?.postDecoded(TypingEvent.self, name: .realtimeTypingStop, from: data)
        }
        socket.on("match:new") { [weak self] data, _ in
            self?.postDecoded(MatchSocketEvent.self, name: .realtimeMatchNew, from: data)
        }
        socket.on("match:stage_changed") { [weak self] data, _ in
            self?.postDecoded(MatchStageSocketEvent.self, name: .realtimeMatchStageChanged, from: data)
        }
        socket.on("match:reveal_request") { [weak self] data, _ in
            self?.postDecoded(MatchRevealSocketEvent.self, name: .realtimeMatchRevealRequest, from: data)
        }
        socket.on("match:revealed") { [weak self] data, _ in
            self?.postDecoded(MatchRevealSocketEvent.self, name: .realtimeMatchRevealed, from: data)
        }
        socket.on("game:invite") { [weak self] data, _ in
            self?.postDecoded(GameInviteSocketEvent.self, name: .realtimeGameInvite, from: data)
        }
        socket.on("game:response") { [weak self] data, _ in
            self?.postDecoded(GameResponseSocketEvent.self, name: .realtimeGameResponse, from: data)
        }
        socket.on("game:cancelled") { [weak self] data, _ in
            self?.postDecoded(GameCancelledSocketEvent.self, name: .realtimeGameCancelled, from: data)
        }
        socket.on("game:state_changed") { [weak self] data, _ in
            self?.postDecoded(GameStateChangedEvent.self, name: .realtimeGameStateChanged, from: data)
        }
    }

    private func postDecoded<T: Decodable>(_ type: T.Type, name: Notification.Name, from data: [Any]) {
        guard let first = data.first,
              let payload: T = decodePayload(first, as: T.self) else { return }
        NotificationCenter.default.post(name: name, object: nil, userInfo: ["payload": payload])
    }

    private func decodePayload<T: Decodable>(_ object: Any, as type: T.Type) -> T? {
        if let payload = object as? T {
            return payload
        }
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
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
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
        }
        return try? decoder.decode(T.self, from: data)
    }
}

extension Notification.Name {
    static let realtimeStatusChanged = Notification.Name("boop.realtime.status")
    static let realtimeError = Notification.Name("boop.realtime.error")
    static let realtimeMessageNew = Notification.Name("boop.realtime.message.new")
    static let realtimeMessageReaction = Notification.Name("boop.realtime.message.reaction")
    static let realtimeMessageRead = Notification.Name("boop.realtime.message.read")
    static let realtimeTypingStart = Notification.Name("boop.realtime.typing.start")
    static let realtimeTypingStop = Notification.Name("boop.realtime.typing.stop")
    static let realtimeMatchNew = Notification.Name("boop.realtime.match.new")
    static let realtimeMatchStageChanged = Notification.Name("boop.realtime.match.stage")
    static let realtimeMatchRevealRequest = Notification.Name("boop.realtime.match.reveal_request")
    static let realtimeMatchRevealed = Notification.Name("boop.realtime.match.revealed")
    static let realtimeGameInvite = Notification.Name("boop.realtime.game.invite")
    static let realtimeGameResponse = Notification.Name("boop.realtime.game.response")
    static let realtimeGameCancelled = Notification.Name("boop.realtime.game.cancelled")
    static let realtimeGameStateChanged = Notification.Name("boop.realtime.game.state")
}
