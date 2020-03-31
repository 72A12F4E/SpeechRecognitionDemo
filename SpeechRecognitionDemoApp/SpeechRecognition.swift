//
//  SpeechRecognition.swift
//  SpeechRecognitionDemoApp
//
//  Created by Blake McAnally on 3/31/20.
//  Copyright © 2020 Blake McAnally. All rights reserved.
//

import Foundation
import Speech

// Sourced heavily from Apple's API Examples
//
// https://developer.apple.com/library/archive/samplecode/SpeakToMe/Listings/SpeakToMe_ViewController_swift.html#//apple_ref/doc/uid/TP40017110-SpeakToMe_ViewController_swift-DontLinkElementID_6
//
public class SpeechRecognizer: ObservableObject {
    
    @Published
    public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    @Published
    public var isRecognitionInProgress: Bool = false
    
    @Published
    public var recognizedSpeech: String?
    
    @Published
    public var isFinalized: Bool = false
    
    private let audioEngine = AVAudioEngine()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?

    deinit {
        self.stopRecording()
    }
    
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
    }
    
    public func recordAndRecognizeSpeech() {
        guard authorizationStatus == .authorized else { return }
        
        // Discard the old recognition task if its still running
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
            isFinalized = false
        }
        
        do {
            isRecognitionInProgress = true
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
            recognitionRequest.shouldReportPartialResults = true
            
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                var isFinal = false
                if let result = result {
                    
                    self.recognizedSpeech = result.bestTranscription.formattedString
                    self.isFinalized = result.isFinal
                    if result.isFinal {
                        isFinal = true
                        self.isRecognitionInProgress = false
                    }
                }
                
                // if there is an error, or we have the final results
                // from speech recognition, stop audio recording
                // and clean up everything
                if error != nil || isFinal {
                    self.stopRecording()
                }
            }
            
            // Hook up the audioEngine to the recognition request
            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.removeTap(onBus: 0) // remove tap to ensure
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func stopRecording() {
        DispatchQueue.main.async {
            self.audioEngine.stop()
            self.audioEngine.inputNode.removeTap(onBus: 0)
            self.recognitionRequest = nil
            self.recognitionTask?.cancel()
            self.recognitionTask?.finish()
            self.recognitionTask = nil
            self.isRecognitionInProgress = false
            self.isFinalized = true
        }
    }
}
