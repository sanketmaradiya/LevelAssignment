//
//  SessionsAPIClient.swift
//  LevelAssignment
//

import Foundation

protocol SessionsFetching {
    func fetchSessions() async throws -> [Session]
}

private struct SessionsResponse: Decodable {
    let sessions: LossyArray<Session>
}

final class SessionsAPIClient: SessionsFetching {
    private let urlSession: URLSession
    private let endpoint: URL

    init(urlSession: URLSession = .shared, endpoint: URL) {
        self.urlSession = urlSession
        self.endpoint = endpoint
    }

    func fetchSessions() async throws -> [Session] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(from: endpoint)
        } catch {
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        do {
            let response = try JSONDecoder().decode(SessionsResponse.self, from: data)
            return response.sessions.elements
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}

extension SessionsAPIClient {
    static func makeDefault() -> SessionsAPIClient {
        let urlString = "https://gist.githubusercontent.com/Manojsuthar2000/441d8e745e124afe601fb85fb1c49a31/raw/sessions.json"
        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid hardcoded sessions endpoint URL")
        }
        return SessionsAPIClient(endpoint: url)
    }
}
