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
    private let maxBuffers = 300 // ~10 seconds at 4096 buffer size

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

    // Get list of all available input devices for menu
    func getAvailableInputDevices() -> [(id: AudioDeviceID, name: String)] {
        var devices: [(id: AudioDeviceID, name: String)] = []
        var seenNames = Set<String>()

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

        guard status == noErr else { return devices }

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

        guard status == noErr else { return devices }

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

                    // Skip speakers/output devices
                    if name.lowercased().contains("speakers") || name.lowercased().contains("output") {
                        continue
                    }

                    // Clean up name - simplify for display
                    var displayName = name
                    if name.contains("AirPods") {
                        displayName = "AirPods Pro"
                    } else if name.lowercased().contains("imac") || name.lowercased().contains("built-in") {
                        displayName = "iMac"
                    }

                    // Skip duplicates
                    if seenNames.contains(displayName) {
                        continue
                    }

                    seenNames.insert(displayName)
                    devices.append((id: deviceID, name: displayName))
                    print("✓ Found input device: \(displayName) (ID: \(deviceID))")
                }
            }
        }

        return devices
    }

    // Find built-in microphone device (iMac, MacBook, etc.)
    private func findBuiltInMicrophone() -> AudioDeviceID? {
        let devices = getAvailableInputDevices()

        // Look for built-in microphone
        let builtIn = devices.first { device in
            let name = device.name.lowercased()
            return name.contains("built-in") ||
                   name.contains("imac") ||
                   name.contains("macbook") ||
                   name.contains("internal")
        }

        if let device = builtIn {
            print("✓ Found built-in microphone: \(device.name) (ID: \(device.id))")
            return device.id
        } else {
            print("⚠️ Could not find built-in microphone")
            return nil
        }
    }

    // Programmatically set the input device for AVAudioEngine
    private func setInputDevice(deviceID: AudioDeviceID) {
        var deviceID = deviceID
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )

        if status == noErr {
            print("✓ Input device set successfully")
        } else {
            print("⚠️ Failed to set input device (status: \(status))")
        }
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

        // Force selection of built-in microphone (ignore AirPods for reliability)
        if let builtInMic = findBuiltInMicrophone() {
            print("✓ Forcing built-in microphone for recording (AirPods will be used for output only)")
            setInputDevice(deviceID: builtInMic)
        } else {
            print("⚠️ Could not find built-in microphone, using system default")
        }

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
            // Clean up on failure
            input.removeTap(onBus: 0)
            audioEngine = nil
            inputNode = nil
            isRecording = false
        }
    }

    private func stopRealAudioRecording() {
        // Ensure tap is removed before stopping engine
        if let input = inputNode {
            input.removeTap(onBus: 0)
        }

        // Stop engine if it's running
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
        }

        // Clear references
        audioEngine = nil
        inputNode = nil

        // Reset audio level
        onAudioLevelUpdate?(0.0)

        print("✓ Captured \(recordedBuffers.count) audio buffers")

        // DON'T clear buffers here - they're needed for getAudioData()
        // Buffers will be cleared at the start of next recording
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Store buffer for transcription (copy it to avoid memory issues)
        // Limit buffer count to prevent unbounded memory growth
        if recordedBuffers.count < maxBuffers {
            if let copy = buffer.copy() as? AVAudioPCMBuffer {
                recordedBuffers.append(copy)
            }
        } else {
            // If we've hit the limit, just log a warning
            if recordedBuffers.count == maxBuffers {
                print("⚠️ Reached maximum buffer limit (\(maxBuffers)), no longer storing audio")
            }
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
