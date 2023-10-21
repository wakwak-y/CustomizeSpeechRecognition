//
//  ListenViewModel.swift
//  CustomizeSpeechRecognition
//
//  Created by 和久井侑 on 2023/10/21.
//

import Foundation
import Combine
import Speech

class ListenViewModel: ObservableObject {
    @Published var isRecordButtonEnabled = true
    @Published var isRecording = false
    @Published var speechResult: String = ""
    
    private var speechRecognizer = SpeechRecognizer()
    
    private var cancellables: Set<AnyCancellable> = .init()
    
    init() {
        speechRecognizer
            .recordEnabled
            .receive(on: OperationQueue.main)
            .sink { recordEnabled in
                self.isRecordButtonEnabled = recordEnabled
            }
            .store(in: &cancellables) // Combineのsubscriptionに登録
        
        speechRecognizer
            .speechResult
            .receive(on: OperationQueue.main)
            .sink { result  in
                self.speechResult += "\n\(result)"
            }
            .store(in: &cancellables)
        
        speechRecognizer.requestAuthorize()
        
        do {
            try speechRecognizer.setup()
        } catch {
            speechResult = "\(error)"
        }
    }
    
    deinit {
        // メモリリークを防ぐために、格納されたsubscriptionを解除する
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    func pressedRecordButton() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
        } else {
            do {
                isRecording = true
                speechResult = ""
                try speechRecognizer.startRecording()
            } catch {
                speechResult = "\(error)"
            }
        }
    }
}
