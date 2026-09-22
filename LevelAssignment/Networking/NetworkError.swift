//
//  NetworkError.swift
//  LevelAssignment
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .requestFailed:
            return "Couldn't reach the server. Check your connection and try again."
        case .decodingFailed:
            return "The session data couldn't be read."
        }
    }
}
