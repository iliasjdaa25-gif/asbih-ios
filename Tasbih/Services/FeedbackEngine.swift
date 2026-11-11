import AVFoundation
import UIKit

/// Provides zero-latency tactile haptics and an in-memory synthesized acoustic bead click.
@MainActor
final class FeedbackEngine {
    private let tapGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let milestoneGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private var players: [AVAudioPlayer] = []
    private var playerIndex = 0
    private var audioConfigured = false

    init() {
        tapGenerator.prepare()
        milestoneGenerator.prepare()
    }

    func prepare() {
        tapGenerator.prepare()
        milestoneGenerator.prepare()
    }

    func triggerTap(hapticEnabled: Bool, soundEnabled: Bool, isMilestone: Bool) {
        if hapticEnabled {
            if isMilestone {
                milestoneGenerator.impactOccurred(intensity: 0.95)
                milestoneGenerator.prepare()
            } else {
                tapGenerator.impactOccurred(intensity: 0.78)
                tapGenerator.prepare()
            }
        }

        if soundEnabled {
            playClick(volume: isMilestone ? 0.65 : 0.48)
        }
    }

    private func playClick(volume: Float) {
        ensureAudioReady()
        guard !players.isEmpty else { return }

        let player = players[playerIndex]
        playerIndex = (playerIndex + 1) % players.count
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    private func ensureAudioReady() {
        guard !audioConfigured else { return }
        audioConfigured = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session failure is non-fatal; skip sound gracefully.
        }

        let wavData = Self.synthesizeBeadClickWAV()
        var pool: [AVAudioPlayer] = []
        pool.reserveCapacity(4)

        for _ in 0..<4 {
            if let player = try? AVAudioPlayer(data: wavData) {
                player.prepareToPlay()
                pool.append(player)
            }
        }
        players = pool
    }

    /// Generates a subtle 22ms acoustic wooden-bead click in PCM WAV format.
    private static func synthesizeBeadClickWAV() -> Data {
        let sampleRate: Int = 44_100
        let sampleCount: Int = 970 // ~22ms
        let dataSize = sampleCount * 2

        var data = Data()
        data.reserveCapacity(44 + dataSize)

        func appendASCII(_ str: String) {
            data.append(contentsOf: str.utf8)
        }

        func appendUInt32(_ value: UInt32) {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }

        func appendUInt16(_ value: UInt16) {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }

        func appendInt16(_ value: Int16) {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }

        // Standard RIFF/WAVE PCM header
        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16)
        appendUInt16(1) // PCM
        appendUInt16(1) // Mono
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))
        appendUInt16(2)
        appendUInt16(16)
        appendASCII("data")
        appendUInt32(UInt32(dataSize))

        let twoPi = 2.0 * Double.pi
        for i in 0..<sampleCount {
            let t = Double(i) / Double(sampleRate)
            // Smooth 0.7ms attack envelope to prevent speaker pop
            let attack = t < 0.0007 ? (0.5 - 0.5 * cos(Double.pi * (t / 0.0007))) : 1.0
            let body = sin(twoPi * 1180.0 * t) * exp(-t * 250.0) * 0.52
            let transient = sin(twoPi * 2450.0 * t) * exp(-t * 430.0) * 0.28
            let warmth = sin(twoPi * 390.0 * t) * exp(-t * 175.0) * 0.22

            let sample = max(-0.85, min(0.85, (body + transient + warmth) * attack))
            appendInt16(Int16(sample * 32767.0))
        }

        return data
    }
}
