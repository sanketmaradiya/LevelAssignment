//
//  SessionRowView.swift
//  LevelAssignment
//

import SwiftUI

struct SessionRowView: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.title)
                        .font(.headline)
                        .lineLimit(1)
                    if session.isPremium {
                        PremiumBadge()
                    }
                }

                Text(session.teacher)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private var artwork: some View {
        AsyncImage(url: session.artworkURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                artworkPlaceholder
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: "waveform")
                    .foregroundStyle(.secondary)
            )
    }
}

private struct PremiumBadge: View {
    var body: some View {
        Text("PREMIUM")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.yellow.opacity(0.25), in: Capsule())
            .foregroundStyle(.orange)
    }
}

#Preview {
    List {
        SessionRowView(session: Session(
            id: "1",
            title: "Morning Calm",
            teacher: "Ranveer",
            durationSeconds: 600,
            artworkURL: URL(string: "https://picsum.photos/200?1"),
            audioURL: nil,
            isPremium: true
        ))
        SessionRowView(session: .placeholder)
            .redacted(reason: .placeholder)
    }
}
