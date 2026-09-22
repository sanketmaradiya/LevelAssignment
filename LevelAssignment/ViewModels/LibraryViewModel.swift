//
//  LibraryViewModel.swift
//  LevelAssignment
//

import Combine
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    let skeletonRowCount = 8

    @Published private(set) var sessions: [Session] = []
    @Published private(set) var loadState: LoadState = .loading
    @Published var refreshErrorMessage: String?

    private let sessionsFetching: SessionsFetching

    init(sessionsFetching: SessionsFetching = SessionsAPIClient.makeDefault()) {
        self.sessionsFetching = sessionsFetching
    }

    func loadSessions() async {
        guard sessions.isEmpty else { return }
        loadState = .loading
        do {
            sessions = try await sessionsFetching.fetchSessions()
            loadState = .loaded
        } catch {
            loadState = .failed(message(for: error))
        }
    }

    func refresh() async {
        do {
            sessions = try await sessionsFetching.fetchSessions()
            loadState = .loaded
            refreshErrorMessage = nil
        } catch {
            refreshErrorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
    }
}
