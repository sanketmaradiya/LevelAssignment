//
//  PlayerViewController.swift
//  LevelAssignment
//

import UIKit

final class PlayerViewController: UIViewController {

    @IBOutlet private var artworkImageView: UIImageView?
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var teacherLabel: UILabel?
    @IBOutlet private var progressSlider: UISlider?
    @IBOutlet private var elapsedTimeLabel: UILabel?
    @IBOutlet private var remainingTimeLabel: UILabel?
    @IBOutlet private var speedButton: UIButton?
    @IBOutlet private var playPauseButton: UIButton?
    @IBOutlet private var backButton: UIButton?
    @IBOutlet private var skipBackButton: UIButton?
    @IBOutlet private var skipForwardButton: UIButton?
    @IBOutlet private var premiumBadgeView: UIView?
    @IBOutlet private var premiumCrownImageView: UIImageView?

    private let viewModel: PlayerViewModel
    private var isScrubbing = false
    private var artworkLoadTask: Task<Void, Never>?

    init(session: Session) {
        viewModel = PlayerViewModel(session: session)
        super.init(nibName: "PlayerViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("PlayerViewController does not support loading from a storyboard.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStaticContent()
        bindViewModel()
        configureActions()
        viewModel.prepare()
        loadArtwork()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        artworkLoadTask?.cancel()
        viewModel.teardown()
    }

    private func configureStaticContent() {
        titleLabel?.text = viewModel.session.title
        titleLabel?.font = UIFontMetrics(forTextStyle: .title1).scaledFont(
            for: .systemFont(ofSize: 26, weight: .bold)
        )
        teacherLabel?.text = viewModel.session.teacher
        elapsedTimeLabel?.text = "0:00"
        remainingTimeLabel?.text = "-\(viewModel.session.formattedDuration)"
        progressSlider?.value = 0
        speedButton?.setTitle(viewModel.currentSpeed.label, for: .normal)
        premiumBadgeView?.isHidden = !viewModel.session.isPremium
        premiumCrownImageView?.image = UIImage(systemName: "crown.fill")

        backButton?.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton?.tintColor = .label
        skipBackButton?.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        skipBackButton?.tintColor = .label
        skipForwardButton?.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        skipForwardButton?.tintColor = .label

        playPauseButton?.tintColor = .white
        playPauseButton?.isEnabled = false
        playPauseButton?.layer.cornerRadius = 30
        updatePlayPauseImage(isPlaying: false)
    }

    private func configureActions() {
        playPauseButton?.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        speedButton?.addTarget(self, action: #selector(didTapSpeed), for: .touchUpInside)
        backButton?.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        skipBackButton?.addTarget(self, action: #selector(didTapSkipBack), for: .touchUpInside)
        skipForwardButton?.addTarget(self, action: #selector(didTapSkipForward), for: .touchUpInside)
        progressSlider?.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        progressSlider?.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider?.addTarget(
            self,
            action: #selector(sliderTouchUp),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
    }

    private func bindViewModel() {
        viewModel.onReadyToPlay = { [weak self] in
            self?.playPauseButton?.isEnabled = true
        }

        viewModel.onFailure = { [weak self] message in
            self?.showFailureAlert(message: message)
        }

        viewModel.onPlaybackStateChange = { [weak self] isPlaying in
            self?.updatePlayPauseImage(isPlaying: isPlaying)
        }

        viewModel.onSpeedChange = { [weak self] speed in
            self?.speedButton?.setTitle(speed.label, for: .normal)
        }

        viewModel.onTimeUpdate = { [weak self] elapsed, remaining, progress in
            guard let self, !self.isScrubbing else { return }
            self.elapsedTimeLabel?.text = Self.formattedTime(elapsed)
            self.remainingTimeLabel?.text = "-\(Self.formattedTime(remaining))"
            self.progressSlider?.value = progress
        }
    }

    private func updatePlayPauseImage(isPlaying: Bool) {
        let symbolName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton?.setImage(UIImage(systemName: symbolName), for: .normal)
    }

    private func loadArtwork() {
        guard let url = viewModel.session.artworkURL else { return }
        artworkLoadTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }
                self?.artworkImageView?.image = image
            } catch {
                // Artwork is purely decorative; a failed fetch should never block playback.
            }
        }
    }

    private func showFailureAlert(message: String) {
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapPlayPause() {
        viewModel.togglePlayPause()
    }

    @objc private func didTapSpeed() {
        viewModel.cycleSpeed()
    }

    @objc private func didTapSkipBack() {
        viewModel.skip(by: -15)
    }

    @objc private func didTapSkipForward() {
        viewModel.skip(by: 15)
    }

    @objc private func sliderTouchDown() {
        isScrubbing = true
    }

    @objc private func sliderValueChanged() {
        guard let progress = progressSlider?.value, let duration = viewModel.duration else { return }
        let elapsed = Double(progress) * duration
        elapsedTimeLabel?.text = Self.formattedTime(elapsed)
        remainingTimeLabel?.text = "-\(Self.formattedTime(max(duration - elapsed, 0)))"
    }

    @objc private func sliderTouchUp() {
        guard let progress = progressSlider?.value else {
            isScrubbing = false
            return
        }
        viewModel.seek(toProgress: progress)
        isScrubbing = false
    }

    private static func formattedTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds.rounded())
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
