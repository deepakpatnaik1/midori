//
//  AudioRecorder.swift
//  midori
//
//  Captures audio from built-in microphone only
//  Handles audio route changes gracefully (e.g., AirPods connecting)
//

import AVFoundation
import CoreAudio

class AudioRecorder {
    private var engine: AVAudioEngine?
    private var buffers: [AVAudioPCMBuffer] = []
    private let maxBuffers = 300  // ~10 seconds
    private var builtInMicID: AudioDeviceID?
    private var isCurrentlyRecording = false
    private let recordingLock = NSLock()

    // Gain multiplier for soft speech (2.5x boost)
    private let audioGain: Float = 2.5

    var onAudioLevelUpdate: ((Float) -> Void)?
    var onDeviceError: ((String) -> Void)?

    init() {
        builtInMicID = findBuiltInMicrophoneID()
        forceBuiltInMicrophone()
        setupAudioNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Audio Route Change Handling

    private func setupAudioNotifications() {
        // Listen for audio hardware configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioConfigurationChange),
            name: NSNotification.Name.AVAudioEngineConfigurationChange,
            object: nil
        )
    }

    @objc private func handleAudioConfigurationChange(_ notification: Notification) {
        print("⚠️ Audio configuration changed (device connected/disconnected)")

        recordingLock.lock()
        let wasRecording = isCurrentlyRecording
        recordingLock.unlock()

        // Always force built-in mic when configuration changes
        builtInMicID = findBuiltInMicrophoneID()
        forceBuiltInMicrophone()

        if wasRecording {
            print("🔄 Restarting recording with built-in microphone...")
            restartRecordingEngine()
        }
    }

    private func restartRecordingEngine() {
        guard let engine = engine else { return }

        // Stop current engine safely
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        // Small delay to let audio system settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.reinstallTapAndStart()
        }
    }

    private func reinstallTapAndStart() {
        guard let engine = engine else { return }

        // Force built-in mic again before reinstalling tap
        forceBuiltInMicrophone()

        let input = engine.inputNode

        // Install fresh tap with nil format (auto-detect hardware format)
        input.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }

        do {
            try engine.start()
            print("✓ Audio engine restarted successfully with built-in mic")
        } catch {
            print("❌ Failed to restart audio engine: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.onDeviceError?("Microphone unavailable. Please check your audio settings.")
            }
        }
    }

    func startRecording() {
        buffers.removeAll()

        // Always force built-in mic before recording
        builtInMicID = findBuiltInMicrophoneID()
        forceBuiltInMicrophone()

        engine = AVAudioEngine()
        guard let engine = engine else {
            print("❌ Failed to create AVAudioEngine")
            return
        }

        let input = engine.inputNode

        // Use nil format to let AVAudioEngine use the hardware's native format
        // This prevents "Input HW format and tap format not matching" crashes
        input.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }

        do {
            try engine.start()
            recordingLock.lock()
            isCurrentlyRecording = true
            recordingLock.unlock()
            print("✓ Recording started with built-in microphone")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.onDeviceError?("Could not start recording. Please try again.")
            }
        }
    }

    func stopRecording() {
        recordingLock.lock()
        isCurrentlyRecording = false
        recordingLock.unlock()

        guard let engine = engine else { return }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil

        onAudioLevelUpdate?(0)
        print("✓ Recording stopped")
    }

    // MARK: - Buffer Handling

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

    func getAudioData() -> Data? {
        guard let buffer = combineBuffers() else { return nil }

        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        guard let mData = audioBuffer.mData else { return nil }
        return Data(bytes: mData, count: Int(audioBuffer.mDataByteSize))
    }

    // MARK: - Built-in Microphone

    private func forceBuiltInMicrophone() {
        guard let deviceID = builtInMicID else {
            print("Built-in microphone not found")
            return
        }

        var id = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &id
        )
    }

    private func findBuiltInMicrophoneID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr else {
            return nil
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: deviceCount)

        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &devices) == noErr else {
            return nil
        }

        for deviceID in devices {
            if isBuiltInMicrophone(deviceID) {
                return deviceID
            }
        }

        return nil
    }

    private func isBuiltInMicrophone(_ deviceID: AudioDeviceID) -> Bool {
        // Check for input channels
        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &dataSize) == noErr,
              dataSize > 0 else {
            return false
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }

        guard AudioObjectGetPropertyData(deviceID, &inputAddress, 0, nil, &dataSize, bufferList) == noErr,
              bufferList.pointee.mBuffers.mNumberChannels > 0 else {
            return false
        }

        // Check transport type
        var transportType: UInt32 = 0
        var transportSize = UInt32(MemoryLayout<UInt32>.size)
        var transportAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectGetPropertyData(deviceID, &transportAddress, 0, nil, &transportSize, &transportType) == noErr else {
            return false
        }

        return transportType == kAudioDeviceTransportTypeBuiltIn
    }

    // MARK: - Buffer Processing

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
