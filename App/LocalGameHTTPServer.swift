import Foundation
import Network

final class LocalGameHTTPServer {
    private let gameRoot: URL
    private let gameID: String
    private let preferredPort: UInt16?
    private let queue = DispatchQueue(label: "LocalGameHTTPServer")
    private var listener: NWListener?
    private var baseURL: URL?

    init(gameRoot: URL, gameID: String, preferredPort: UInt16? = nil) {
        self.gameRoot = gameRoot.standardizedFileURL
        self.gameID = gameID
        self.preferredPort = preferredPort
    }

    func start() async throws -> URL {
        if let baseURL { return baseURL }
        let port = preferredPort.flatMap(NWEndpoint.Port.init(rawValue:)) ?? .any
        let listener = try NWListener(using: .tcp, on: port)
        self.listener = listener
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            listener.stateUpdateHandler = { [weak self] state in
                guard let self, !resumed else { return }
                switch state {
                case .ready:
                    guard let port = listener.port,
                          let url = URL(string: "http://127.0.0.1:\(port.rawValue)/games/\(gameID)/") else {
                        resumed = true
                        continuation.resume(throwing: GameFileError.invalidPath)
                        return
                    }
                    resumed = true
                    self.baseURL = url
                    continuation.resume(returning: url)
                case .failed(let error):
                    resumed = true
                    continuation.resume(throwing: error)
                case .cancelled:
                    resumed = true
                    continuation.resume(throwing: CancellationError())
                default:
                    break
                }
            }
            listener.start(queue: queue)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        baseURL = nil
    }

    deinit {
        listener?.cancel()
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection, accumulated: Data())
    }

    private func receiveRequest(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var requestData = accumulated
            if let data { requestData.append(data) }
            if requestData.range(of: Data("\r\n\r\n".utf8)) != nil || isComplete {
                self.respond(to: connection, requestData: requestData)
            } else if error == nil, requestData.count < 65_536 {
                self.receiveRequest(on: connection, accumulated: requestData)
            } else {
                self.send(status: 400, body: Data("Bad Request".utf8), mimeType: "text/plain; charset=utf-8", method: "GET", on: connection)
            }
        }
    }

    private func respond(to connection: NWConnection, requestData: Data) {
        guard let requestText = String(data: requestData, encoding: .utf8),
              let firstLine = requestText.components(separatedBy: "\r\n").first else {
            send(status: 400, body: Data("Bad Request".utf8), mimeType: "text/plain; charset=utf-8", method: "GET", on: connection)
            return
        }
        let parts = firstLine.split(separator: " ").map(String.init)
        guard parts.count >= 2 else {
            send(status: 400, body: Data("Bad Request".utf8), mimeType: "text/plain; charset=utf-8", method: "GET", on: connection)
            return
        }
        let method = parts[0]
        guard method == "GET" || method == "HEAD" else {
            send(status: 405, body: Data(), mimeType: "text/plain; charset=utf-8", method: method, on: connection)
            return
        }
        guard let components = URLComponents(string: parts[1]) else {
            send(status: 400, body: Data("Bad Request".utf8), mimeType: "text/plain; charset=utf-8", method: method, on: connection)
            return
        }
        do {
            let route = try LocalGameHTTPRoute.parse(path: components.percentEncodedPath, expectedGameID: gameID)
            let requestURL = URL(string: "rpg-game://localhost/\(route.relativePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? route.relativePath)")!
            let resource = try GameResourceResolver.resolve(requestURL: requestURL, gameRoot: gameRoot)
            let responseData = GameRuntimeCompatibilityPatcher.patch(
                resource.data,
                relativePath: route.relativePath
            )
            send(
                status: 200,
                body: responseData,
                mimeType: resource.textEncodingName.map { "\(resource.mimeType); charset=\($0)" } ?? resource.mimeType,
                method: method,
                on: connection
            )
        } catch let error as GameFileError {
            send(status: statusCode(for: error), body: Data((error.errorDescription ?? "Not Found").utf8), mimeType: "text/plain; charset=utf-8", method: method, on: connection)
        } catch {
            send(status: 500, body: Data(error.localizedDescription.utf8), mimeType: "text/plain; charset=utf-8", method: method, on: connection)
        }
    }

    private func statusCode(for error: GameFileError) -> Int {
        switch error {
        case .missingResource: return 404
        case .invalidPath, .absolutePath, .pathTraversal: return 400
        }
    }


    private func send(status: Int, body: Data, mimeType: String, method: String, on connection: NWConnection) {
        let reason: String
        switch status {
        case 200: reason = "OK"
        case 400: reason = "Bad Request"
        case 404: reason = "Not Found"
        case 405: reason = "Method Not Allowed"
        default: reason = "Internal Server Error"
        }
        let headers = "HTTP/1.1 \(status) \(reason)\r\n" +
            "Content-Type: \(mimeType)\r\n" +
            "Content-Length: \(body.count)\r\n" +
            "Cache-Control: no-store\r\n" +
            "Access-Control-Allow-Origin: *\r\n" +
            "Connection: close\r\n" +
            "\r\n"
        var response = Data(headers.utf8)
        if method != "HEAD" { response.append(body) }
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}
