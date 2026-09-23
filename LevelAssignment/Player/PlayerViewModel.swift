//
//  PlayerViewModel.swift
//  LevelAssignment
//

import AVFoundation
import Foundation

final class PlayerViewModel {
    enum PlaybackSpeed: Double, CaseIterable {
        case normal = 1.0
        case oneAndHalf = 1.5
        case double = 2.0

        var next: PlaybackSpeed {
            switch self {
            case .normal: return .oneAndHalf
            case .oneAndHalf: return .double
            case .double: return .normal
            }
        }

        var label: String {
            switch self {
            case .normal: return "1x"
            case .oneAndHalf: return "1.5x"
            case .double: return "2x"
            }
        }
    }

    let session: Session

    private(set) var isPlaying = false
    private(set) var currentSpeed: PlaybackSpeed = .normal

    var onTimeUpdate: ((TimeInterval, TimeInterval, Float) -> Void)?
    var onPlaybackStateChange: ((Bool) -> Void)?
    var onSpeedChange: ((PlaybackSpeed) -> Void)?
    var onFailure: ((String) -> Void)?
    var onReadyToPlay: (() -> Void)?

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?

    init(session: Session) {
        self.session = session
    }

    func prepare() {
        configureAudioSession()

        guard let audioURL = session.audioURL else {
            onFailure?("This session doesn't have a playable audio file.")
            return
        }

        let item = AVPlayerItem(url: audioURL)
        let player = AVPlayer(playerItem: item)
        self.player = player
        observeStatus(of: item)
        addPeriodicTimeObserver()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            onFailure?("Couldn't configure audio playback.")
        }
    }

    private func observeStatus(of item: AVPlayerItem) {
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                DispatchQueue.main.async { self.onReadyToPlay?() }
            case .failed:
                DispatchQueue.main.async {
                    self.onFailure?("This session's audio couldn't be loaded.")
                }
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }

    private func addPeriodicTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let duration = self.player?.currentItem?.duration, duration.isNumeric else { return }
            let elapsed = time.seconds
            let total = duration.seconds
            let remaining = max(total - elapsed, 0)
            let progress: Float = total > 0 ? Float(elapsed / total) : 0
            self.onTimeUpdate?(elapsed, remaining, progress)
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.rate = Float(currentSpeed.rawValue)
        }
        isPlaying.toggle()
        onPlaybackStateChange?(isPlaying)
    }

    func seek(toProgress progress: Float) {
        guard let player, let duration = player.currentItem?.duration, duration.isNumeric else { return }
        let targetSeconds = Double(progress) * duration.seconds
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    func skip(by seconds: TimeInterval) {
        guard let player, let duration = player.currentItem?.duration, duration.isNumeric else { return }
        let targetSeconds = min(max(player.currentTime().seconds + seconds, 0), duration.seconds)
        player.seek(to: CMTime(seconds: targetSeconds, preferredTimescale: 600))
    }

    func cycleSpeed() {
        currentSpeed = currentSpeed.next
        if isPlaying {
            player?.rate = Float(currentSpeed.rawValue)
        }
        onSpeedChange?(currentSpeed)
    }

    var duration: TimeInterval? {
        guard let duration = player?.currentItem?.duration, duration.isNumeric else { return nil }
        return duration.seconds
    }

    func teardown() {
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        statusObservation?.invalidate()
        player?.pause()
        player = nil
    }

    deinit {
        statusObservation?.invalidate()
    }
}
