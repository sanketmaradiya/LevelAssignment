//
//  Session.swift
//  LevelAssignment
//

import Foundation

struct Session: Identifiable, Equatable {
    let id: String
    let title: String
    let teacher: String
    let durationSeconds: Int
    let artworkURL: URL?
    let audioURL: URL?
    let isPremium: Bool

    static let placeholder = Session(
        id: "placeholder",
        title: "Loading session title",
        teacher: "Loading teacher name",
        durationSeconds: 600,
        artworkURL: nil,
        audioURL: nil,
        isPremium: false
    )

    var formattedDuration: String {
        let clamped = max(durationSeconds, 0)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Session: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, title, teacher
        case durationSeconds = "duration_seconds"
        case artworkURL = "artwork_url"
        case audioURL = "audio_url"
        case isPremium = "is_premium"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled Session"
        teacher = (try? container.decode(String.self, forKey: .teacher)) ?? "Unknown Teacher"
        durationSeconds = (try? container.decode(Int.self, forKey: .durationSeconds)) ?? 0
        isPremium = (try? container.decode(Bool.self, forKey: .isPremium)) ?? false

        let artworkURLString = try? container.decode(String.self, forKey: .artworkURL)
        artworkURL = artworkURLString.flatMap(URL.init(string:))

        let audioURLString = try? container.decode(String.self, forKey: .audioURL)
        audioURL = audioURLString.flatMap(URL.init(string:))
    }
}
