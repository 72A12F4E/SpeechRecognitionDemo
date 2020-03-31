//
//  ContentView.swift
//  SpeechRecognitionDemoApp
//
//  Created by Blake McAnally on 3/31/20.
//  Copyright © 2020 Blake McAnally. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject
    var recognizer: SpeechRecognizer
    
    var body: some View {
        VStack {
            Text((recognizer.recognizedSpeech ?? ""))
            Spacer()
            Button(recognizer.isRecognitionInProgress ? "recording" : "Tap To Recognize Speech", action: {
                self.recognizer.recordAndRecognizeSpeech()
            })
        }.onAppear {
            self.recognizer.requestAuthorization()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
