//
//  AudioRecorder.swift
//  midori
//
//  Audio recording with AVAudioEngine
//  Uses mock data initially to avoid permission dialog issues during development
//

import AVFoundation
import CoreAudio
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

    func preconfigureAudioDevice() {
        // No longer needed - we'll set the device on AVAudioEngine directly
        // This avoids changing the system-wide default which causes audio interruptions
        print("🔧 Device configuration will happen during engine setup...")
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

        // Use the format that the current input device provides
        // Don't try to override the device - just use whatever is default
        let format = input.outputFormat(forBus: 0)
        print("✓ Recording format: \(format.sampleRate)Hz, \(format.channelCount) channels")

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

    private func findBuiltInMicrophone() -> AudioDeviceID? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        guard status == noErr else { return nil }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &audioDevices
        )

        guard status == noErr else { return nil }

        for deviceID in audioDevices {
            var inputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )

            var inputDataSize: UInt32 = 0
            status = AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &inputDataSize)

            if status == noErr && inputDataSize > 0 {
                var nameAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )

                var deviceName: Unmanaged<CFString>?
                var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>>.size)
                status = AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &deviceName)

                if status == noErr, let cfName = deviceName?.takeUnretainedValue() {
                    let name = cfName as String
                    if name.lowercased().contains("built-in") ||
                       name.lowercased().contains("macbook") ||
                       name.lowercased().contains("imac") ||
                       name.lowercased().contains("mac mini") ||
                       name.lowercased().contains("internal") {
                        print("✓ Found built-in microphone: \(name) (ID: \(deviceID))")
                        return deviceID
                    }
                }
            }
        }

        return nil
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
