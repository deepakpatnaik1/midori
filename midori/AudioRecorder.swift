//
//  AudioRecorder.swift
//  midori
//
//  Audio capture with support for any input device (built-in mic, AirPods, etc.)
//

import AVFoundation
import CoreAudio

class AudioRecorder {
    private var engine: AVAudioEngine?
    private var buffers: [AVAudioPCMBuffer] = []
    private let maxBuffers = 54000  // ~30 minutes (safety valve only)

    // Gain multiplier for soft speech (2.5x boost)
    private let audioGain: Float = 2.5

    // Track if we're currently recording (for device change handling)
    private var isRecording = false

    var onAudioLevelUpdate: ((Float) -> Void)?
    var onDeviceDisconnected: (() -> Void)?

    init() {
        setupDeviceChangeNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startRecording() {
        buffers.removeAll()

        engine = AVAudioEngine()
        guard let engine = engine else {
            print("❌ Failed to create AVAudioEngine")
            return
        }

        // Log current input device
        logCurrentInputDevice()

        let input = engine.inputNode

        // Use nil format to let AVAudioEngine use the hardware's native format
        input.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }

        do {
            try engine.start()
            isRecording = true
            print("✓ Recording started")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() {
        isRecording = false
        guard let engine = engine else { return }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil

        onAudioLevelUpdate?(0)
        print("✓ Recording stopped")
    }

    // MARK: - Device Management

    private func setupDeviceChangeNotification() {
        // Listen for audio configuration changes (device connect/disconnect)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: nil
        )
    }

    @objc private func handleConfigurationChange(_ notification: Notification) {
        print("🔊 Audio configuration changed")
        logCurrentInputDevice()

        // If we were recording, we need to rebuild the engine from scratch
        // The old tap is invalid after a configuration change
        if isRecording {
            print("⚠️ Device changed while recording - rebuilding audio engine")

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // 1. Tear down old engine (but keep our buffers!)
                if let oldEngine = self.engine {
                    oldEngine.inputNode.removeTap(onBus: 0)
                    oldEngine.stop()
                }

                // 2. Create fresh engine with new device configuration
                self.engine = AVAudioEngine()
                guard let engine = self.engine else {
                    print("❌ Failed to create new AVAudioEngine")
                    self.onDeviceDisconnected?()
                    return
                }

                // 3. Install new tap (nil format = use new hardware's native format)
                let input = engine.inputNode
                input.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
                    self?.handleAudioBuffer(buffer)
                }

                // 4. Start the new engine
                do {
                    try engine.start()
                    print("✓ Audio engine rebuilt after device change")
                } catch {
                    print("❌ Failed to start rebuilt audio engine: \(error)")
                    self.onDeviceDisconnected?()
                }
            }
        }
    }

    private func logCurrentInputDevice() {
        // Get current default input device name
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0, nil,
            &size, &deviceID
        )

        if status == noErr {
            // Get device name
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            var name: CFString = "" as CFString
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            let nameStatus = AudioObjectGetPropertyData(
                deviceID,
                &nameAddress,
                0, nil,
                &nameSize, &name
            )

            if nameStatus == noErr {
                print("🎤 Input device: \(name)")
            }
        }
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
