//
//  AudioRecorder.swift
//  midori
//
//  Simple audio capture - uses system default input device
//

import AVFoundation

class AudioRecorder {
    private var engine: AVAudioEngine?
    private var buffers: [AVAudioPCMBuffer] = []
    private let maxBuffers = 54000  // ~30 minutes (safety valve only)

    // Gain multiplier for soft speech (2.5x boost)
    private let audioGain: Float = 2.5

    var onAudioLevelUpdate: ((Float) -> Void)?

    func startRecording() {
        buffers.removeAll()

        engine = AVAudioEngine()
        guard let engine = engine else {
            print("❌ Failed to create AVAudioEngine")
            return
        }

        let input = engine.inputNode

        // Use nil format to let AVAudioEngine use the hardware's native format
        input.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }

        do {
            try engine.start()
            print("✓ Recording started")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() {
        guard let engine = engine else { return }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil

        onAudioLevelUpdate?(0)
        print("✓ Recording stopped")
    }

    func getAudioData() -> Data? {
        guard let buffer = combineBuffers() else { return nil }

        guard let floatData = buffer.floatChannelData else { return nil }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return nil }

        let samples = floatData[0]
        return Data(bytes: samples, count: frameCount * MemoryLayout<Float>.size)
    }

    // MARK: - Private

    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Store buffer copy
        if buffers.count < maxBuffers,
           let copy = buffer.copy() as? AVAudioPCMBuffer {
            buffers.append(copy)
        }

        // Calculate RMS for waveform
        guard let data = buffer.floatChannelData else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }

        var sum: Float = 0
        for i in 0..<count {
            let sample = data[0][i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(count))
        let level = min(rms * 10, 1.0)

        DispatchQueue.main.async { [weak self] in
            self?.onAudioLevelUpdate?(level)
        }
    }

    private func combineBuffers() -> AVAudioPCMBuffer? {
        guard !buffers.isEmpty, let format = buffers.first?.format else { return nil }

        let totalFrames = buffers.reduce(0) { $0 + $1.frameLength }
        guard totalFrames > 0,
              let combined = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            return nil
        }

        var offset: AVAudioFrameCount = 0
        for buffer in buffers {
            let frames = buffer.frameLength
            guard let src = buffer.floatChannelData,
                  let dst = combined.floatChannelData else { continue }

            for channel in 0..<Int(format.channelCount) {
                for i in 0..<Int(frames) {
                    var sample = src[channel][i] * audioGain
                    // Soft clip
                    if sample > 1.0 {
                        sample = 1.0 - (1.0 / (sample + 1.0))
                    } else if sample < -1.0 {
                        sample = -1.0 + (1.0 / (-sample + 1.0))
                    }
                    dst[channel][Int(offset) + i] = sample
                }
            }
            offset += frames
        }
        combined.frameLength = totalFrames

        return combined
    }
}
