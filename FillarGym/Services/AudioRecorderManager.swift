import Foundation
import AVFoundation
import Combine

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioLevels: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var hasPermission = false
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    
    private let maxRecordingDuration: TimeInterval = 600 // 10分
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        self?.hasPermission = allowed
                    }
                }
            @unknown default:
                hasPermission = false
            }
        } else {
            switch audioSession.recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                audioSession.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        self?.hasPermission = allowed
                    }
                }
            @unknown default:
                hasPermission = false
            }
        }
    }
    
    func startRecording() {
        guard hasPermission else {
            errorMessage = "マイクの使用が許可されていません"
            return
        }
        
        guard !isRecording else { return }
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            if audioRecorder?.record() == true {
                isRecording = true
                recordingDuration = 0.0
                startTimers()
            } else {
                errorMessage = "録音を開始できませんでした"
            }
            
        } catch {
            errorMessage = "録音エラー: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        stopTimers()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("AudioSession deactivation error: \(error)")
        }
        
        isRecording = false
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        stopTimers()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("AudioSession deactivation error: \(error)")
        }
        
        isRecording = false
        recordingDuration = 0.0
    }
    
    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            
            // 最大録音時間チェック
            if self.recordingDuration >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            let normalizedLevel = self.normalizedPowerLevel(from: averagePower)
            DispatchQueue.main.async {
                self.audioLevels = normalizedLevel
            }
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
        audioLevels = 0.0
    }
    
    private func normalizedPowerLevel(from power: Float) -> Float {
        if power < -60.0 {
            return 0.0
        } else if power >= 0.0 {
            return 1.0
        } else {
            return (power + 60.0) / 60.0
        }
    }
    
    var recordingURL: URL? {
        return audioRecorder?.url
    }
    
    var remainingTime: TimeInterval {
        return maxRecordingDuration - recordingDuration
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "録音が正常に完了しませんでした"
        }
        isRecording = false
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            errorMessage = "録音エンコードエラー: \(error.localizedDescription)"
        }
        isRecording = false
    }
}