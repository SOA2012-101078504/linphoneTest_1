//
//  ContentView.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var tutorialContext = CallExampleContext()
    
    var body: some View {
        
        VStack(alignment: .leading) {
            VStack(spacing: 0.0) {
                Text("Call Settings")
                    .font(.largeTitle)
                HStack {
                    Text("Call destination :")
                    TextField("", text : $tutorialContext.dest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.top)
            }
            VStack(alignment: .leading) {
                Toggle(isOn: $tutorialContext.audioEnabled) {
                    Text("Audio")
                }.frame(width : 120.0)
                Toggle(isOn: $tutorialContext.videoEnabled) {
                    Text("Video")
                }.frame(width : 120.0)
                Button(action: tutorialContext.changeVideoDevice)
                {
                    Text(" Change camera ")
                        .font(.title)
                        .foregroundColor(Color.white)
                        .background(Color.gray)
                }
                .padding(.vertical)
                HStack {
                    Text("Speaker :")
                    Button(action: tutorialContext.speaker)
                    {
                        Text(tutorialContext.speakerEnabled ? "ON" : "OFF")
                            .font(.title)
                            .foregroundColor(Color.white)
                            .frame(width: 60.0, height: 30.0)
                            .background(Color.gray)
                    }
                }
            }
            .padding(.top, 5.0)
            Spacer()
            VStack {
                HStack {
                    Button(action: tutorialContext.outgoingCallExample)
                    {
                        Text(tutorialContext.callRunning ? "Update Call" : "Call")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 180.0, height: 42.0)
                            .background(Color.green)
                    }
                    Button(action: tutorialContext.stopOutgoingCallExample) {
                        Text("Stop Call")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 180.0, height: 42.0)
                            .background(Color.red)
                    }
                }
                HStack {
                    Text("Call State : ")
                        .font(.footnote)
                    Text(tutorialContext.callRunning ? "Ongoing" : "Stopped")
                        .font(.footnote)
                        .foregroundColor(tutorialContext.callRunning ? Color.green : Color.black)
                }
                .padding(.top)
            }
            Spacer()
            Group {
                Toggle(isOn: $tutorialContext.logsEnabled) {
                    Text("Logs collection")
                        .multilineTextAlignment(.trailing)
                }
                Text("Core Version is \(tutorialContext.coreVersion)")
                    .font(.footnote)
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
