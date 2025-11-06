//
//  AudioRecorder.swift
//  midori
//
//  Audio recording with AVAudioEngine
//  Uses mock data initially to avoid permission dialog issues during development
//

import AVFoundation
import Foundation

class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var isRecording = false
    private var recordedBuffers: [AVAudioPCMBuffer] = []

    // Mock data generation
    private var mockTimer: Timer?
    private var mockTime: Double = 0

    var onAudioLevelUpdate: ((Float) -> Void)?

    init() {
        print("✓ AudioRecorder initialized")
    }

    deinit {
        stopRecording()
    }

    func startRecording() {
        guard !isRecording else { return }
        isRecording = true

        // Real audio recording
        print("🎤 Starting audio recording...")
        startRealAudioRecording()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        stopRealAudioRecording()
        print("🔴 Stopped audio recording")
    }

    func getAudioData() -> Data? {
        // Combine all recorded buffers into one Data object
        guard !recordedBuffers.isEmpty else {
            print("⚠️ No audio recorded")
            return nil
        }

        var combinedData = Data()

        for buffer in recordedBuffers {
            let audioBuffer = buffer.audioBufferList.pointee.mBuffers
            if let data = audioBuffer.mData {
                let bufferData = Data(bytes: data, count: Int(audioBuffer.mDataByteSize))
                combinedData.append(bufferData)
            }
        }

        print("✓ Audio data extracted: \(combinedData.count) bytes from \(recordedBuffers.count) buffers")
        return combinedData
    }

    // MARK: - Mock Audio (Development)

    private func startMockAudioGeneration() {
        mockTime = 0
        mockTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Generate sine wave-based audio level (0.2 to 1.0)
            self.mockTime += 0.05
            let level = (sin(self.mockTime * 3.0) + 1.0) / 2.0 * 0.8 + 0.2

            self.onAudioLevelUpdate?(Float(level))
        }
    }

    private func stopMockAudioGeneration() {
        mockTimer?.invalidate()
        mockTimer = nil
        onAudioLevelUpdate?(0.0)
    }

    // MARK: - Real Audio (Production)

    private func startRealAudioRecording() {
        // Clear previous recordings
        recordedBuffers.removeAll()

        audioEngine = AVAudioEngine()

        guard let engine = audioEngine else {
            print("❌ Failed to create audio engine")
            return
        }

        inputNode = engine.inputNode

        guard let input = inputNode else {
            print("❌ Failed to get input node")
            return
        }

        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }

        do {
            try engine.start()
            print("✓ Audio engine started")
        } catch {
            print("❌ Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func stopRealAudioRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        onAudioLevelUpdate?(0.0)

        print("✓ Captured \(recordedBuffers.count) audio buffers")
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Store buffer for transcription (copy it to avoid memory issues)
        if let copy = buffer.copy() as? AVAudioPCMBuffer {
            recordedBuffers.append(copy)
        }

        // Calculate audio level for visualization
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }

        // Calculate RMS (root mean square) for audio level
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataValueArray.count))

        // Normalize to 0.0-1.0 range
        let level = min(max(rms * 10.0, 0.0), 1.0)

        DispatchQueue.main.async { [weak self] in
            self?.onAudioLevelUpdate?(level)
        }
    }
}
