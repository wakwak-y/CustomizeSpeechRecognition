//
//  SpeechRecognizer.swift
//  CustomizeSpeechRecognition
//
//  Created by 和久井侑 on 2023/10/21.
//

import Foundation
import Combine
import Speech

class SpeechRecognizer: NSObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-Jp"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    
    
    private let recordEnabledSubject: PassthroughSubject<Bool, Never> = .init()
    lazy var recordEnabled: AnyPublisher<Bool, Never> = {
        recordEnabledSubject.eraseToAnyPublisher()
    }()
    
    private let speechResultSubject: PassthroughSubject<String, Never> = .init()
    lazy var speechResult: AnyPublisher<String, Never> = {
        speechResultSubject.eraseToAnyPublisher()
    }()
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
    }
    
    func requestAuthorize() {
        SFSpeechRecognizer.requestAuthorization { status in
            self.recordEnabledSubject.send(status == .authorized)
        }
    }
    
    func setup() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        self.inputNode = audioEngine.inputNode
        audioEngine.prepare()
    }
    
    func startRecording() throws {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        // 音声認識の結果を逐次返す
        recognitionRequest.shouldReportPartialResults = true
        // falseの場合、クラウド上で実行される
        recognitionRequest.requiresOnDeviceRecognition = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, delegate: self)
        
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        try audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recordEnabledSubject.send(false)
    }
}

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        recordEnabledSubject.send(available)
    }
}

extension SpeechRecognizer: SFSpeechRecognitionTaskDelegate {
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        self.speechResultSubject.send(recognitionResult.bestTranscription.formattedString)
        print(recognitionResult.bestTranscription.formattedString)
        
        if recognitionResult.isFinal {
            self.audioEngine.stop()
            self.inputNode?.removeTap(onBus: 0)
            
            self.recognitionRequest = nil
            self.recognitionTask = nil
            
            self.recordEnabledSubject.send(true)
        }
    }
}
