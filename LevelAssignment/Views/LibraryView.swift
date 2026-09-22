//
//  LibraryView.swift
//  LevelAssignment
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    let onSelectSession: (Session) -> Void

    var body: some View {
        content
            .task { await viewModel.loadSessions() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            skeletonList
        case .loaded:
            sessionList
        case .failed(let message):
            if viewModel.sessions.isEmpty {
                ErrorStateView(message: message) {
                    Task { await viewModel.loadSessions() }
                }
            } else {
                sessionList
            }
        }
    }

    private var skeletonList: some View {
        List(0..<viewModel.skeletonRowCount, id: \.self) { _ in
            SessionRowView(session: .placeholder)
                .redacted(reason: .placeholder)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private var sessionList: some View {
        List(viewModel.sessions) { session in
            SessionRowView(session: session)
                .contentShape(Rectangle())
                .onTapGesture { onSelectSession(session) }
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
        .safeAreaInset(edge: .top) {
            if let refreshErrorMessage = viewModel.refreshErrorMessage {
                Text(refreshErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.85))
            }
        }
    }
}
