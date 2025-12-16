//
//  AudioRecorder.swift
//  midori
//
//  Captures audio into AVAudioPCMBuffer for transcription
//  Forces built-in microphone (completely ignores AirPods)
//

import AVFoundation
import CoreAudio

class AudioRecorder {
    private var engine: AVAudioEngine?
    private var buffers: [AVAudioPCMBuffer] = []
    private let maxBuffers = 300  // ~10 seconds
    private var deviceChangeListenerBlock: AudioObjectPropertyListenerBlock?
    private var isRecording = false
    private var builtInMicID: AudioDeviceID?

    // Gain multiplier for soft speech (2.5x boost)
    private let audioGain: Float = 2.5

    var onAudioLevel: ((Float) -> Void)?

    init() {
        // Cache the built-in mic ID at startup
        builtInMicID = findBuiltInMicrophoneID()

        // Force built-in mic immediately
        selectBuiltInMicrophone()

        // Monitor for device changes (e.g., AirPods connecting)
        setupDeviceChangeListener()
    }

    deinit {
        removeDeviceChangeListener()
    }

    func start() {
        buffers.removeAll()
        isRecording = true

        // Force built-in microphone as system default
        selectBuiltInMicrophone()

        engine = AVAudioEngine()
        guard let engine = engine else { return }

        // CRITICAL: Set input device directly on the audio unit
        // This bypasses system default and forces built-in mic
        if let builtInID = builtInMicID {
            setInputDeviceOnEngine(engine, deviceID: builtInID)
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        // Validate format - AirPods can cause invalid formats
        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("Invalid audio format - trying to recover")
            self.engine = nil
            // Wait and retry with fresh engine
            Thread.sleep(forTimeInterval: 0.1)
            start()
            return
        }

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            // Store buffer copy
            if self.buffers.count < self.maxBuffers,
               let copy = buffer.copy() as? AVAudioPCMBuffer {
                self.buffers.append(copy)
            }

            // Calculate RMS for waveform
            if let data = buffer.floatChannelData {
                let count = Int(buffer.frameLength)
                guard count > 0 else { return }
                var sum: Float = 0
                for i in 0..<count {
                    let sample = data[0][i]
                    sum += sample * sample
                }
                let rms = sqrt(sum / Float(count))
                let level = min(rms * 10, 1.0)

                DispatchQueue.main.async {
                    self.onAudioLevel?(level)
                }
            }
        }

        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stop() -> AVAudioPCMBuffer? {
        isRecording = false
        guard let engine = engine else { return nil }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil

        onAudioLevel?(0)

        return combineBuffers()
    }

    // MARK: - Device Change Monitoring

    private func setupDeviceChangeListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        deviceChangeListenerBlock = { [weak self] (_, _) in
            guard let self = self else { return }

            // Check if the new default device is NOT the built-in mic
            let currentDefault = self.getCurrentDefaultInputDevice()
            if let builtIn = self.builtInMicID, currentDefault != builtIn {
                print("Device changed to non-built-in mic (possibly AirPods) - forcing back to built-in")
                self.selectBuiltInMicrophone()
            }
        }

        if let block = deviceChangeListenerBlock {
            AudioObjectAddPropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                DispatchQueue.main,
                block
            )
        }
    }

    private func removeDeviceChangeListener() {
        guard let block = deviceChangeListenerBlock else { return }

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )
        deviceChangeListenerBlock = nil
    }

    private func getCurrentDefaultInputDevice() -> AudioDeviceID {
        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )

        return deviceID
    }

    // MARK: - Force Built-in Microphone

    private func setInputDeviceOnEngine(_ engine: AVAudioEngine, deviceID: AudioDeviceID) {
        // Get the audio unit from the input node
        let inputNode = engine.inputNode
        let audioUnit = inputNode.audioUnit

        guard let au = audioUnit else {
            print("Could not get audio unit from input node")
            return
        }

        // Set the input device directly on the audio unit
        var deviceID = deviceID
        let status = AudioUnitSetProperty(
            au,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &deviceID,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )

        if status == noErr {
            print("Set input device directly on audio unit: \(deviceID)")
        } else {
            print("Failed to set input device on audio unit: \(status)")
        }
    }

    private func selectBuiltInMicrophone() {
        guard let builtInID = findBuiltInMicrophoneID() else {
            print("Could not find built-in microphone")
            return
        }

        var deviceID = builtInID
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
            print("Switched to built-in microphone")
        }
    }

    private func findBuiltInMicrophoneID() -> AudioDeviceID? {
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
        var devices = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &devices
        )
        guard status == noErr else { return nil }

        for deviceID in devices {
            if isBuiltInMicrophone(deviceID) {
                return deviceID
            }
        }

        return nil
    }

    private func isBuiltInMicrophone(_ deviceID: AudioDeviceID) -> Bool {
        // Check if device has input channels
        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return false }

        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferListPointer.deallocate() }

        status = AudioObjectGetPropertyData(deviceID, &inputAddress, 0, nil, &dataSize, bufferListPointer)
        guard status == noErr else { return false }

        let channelCount = bufferListPointer.pointee.mBuffers.mNumberChannels
        guard channelCount > 0 else { return false }

        // Check transport type - built-in devices have kAudioDeviceTransportTypeBuiltIn
        var transportType: UInt32 = 0
        var transportSize = UInt32(MemoryLayout<UInt32>.size)
        var transportAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        status = AudioObjectGetPropertyData(deviceID, &transportAddress, 0, nil, &transportSize, &transportType)
        guard status == noErr else { return false }

        return transportType == kAudioDeviceTransportTypeBuiltIn
    }

    // MARK: - Combine Buffers

    private func combineBuffers() -> AVAudioPCMBuffer? {
        guard !buffers.isEmpty,
              let format = buffers.first?.format else { return nil }

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
                // Apply gain and copy with soft clipping
                for i in 0..<Int(frames) {
                    var sample = src[channel][i] * audioGain
                    // Soft clip to prevent harsh distortion
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
