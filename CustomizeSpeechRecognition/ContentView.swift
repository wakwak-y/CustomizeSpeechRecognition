//
//  ContentView.swift
//  CustomizeSpeechRecognition
//
//  Created by 和久井侑 on 2023/10/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var listenViewModel: ListenViewModel = .init()
    
    var body: some View {
        VStack {
            Spacer()
            Text(listenViewModel.speechResult)
                .frame(width: 300, height: 400)
                .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 3))
            Spacer()
            
            Button(action: {
                 listenViewModel.pressedRecordButton()
            }) {
                Image(systemName: listenViewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .frame(width:  100, height: 100)
                    .aspectRatio(contentMode: .fit)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
