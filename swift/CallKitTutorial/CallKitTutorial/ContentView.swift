//
//  ContentView.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var tutorialContext : CallExampleContext
    
    func getCallButtonText() -> String
    {
        if (tutorialContext.callRunning) {
            return "Update Call"
        }
        else if (tutorialContext.isCallIncoming) {
            return "Answer"
        }
        else {
            return "Call"
        }
    }
    
    func callStateString() -> String
    {
        if (tutorialContext.callRunning) {
            return "Call running"
        }
        else if (tutorialContext.isCallIncoming) {
            return "Incoming call"
        }
        else {
            return "No Call"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                HStack {
                    Text("Identity :")
                        .font(.subheadline)
                    TextField("", text : $tutorialContext.id)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Password :")
                        .font(.subheadline)
                    TextField("", text : $tutorialContext.passwd)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Button(action:  tutorialContext.registrationExample)
                    {
                        Text("Login")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 90.0, height: 42.0)
                            .background(Color.gray)
                    }
                    Spacer()
                    Text("Login State :")
                        .font(.footnote)
                    Text(tutorialContext.loggedIn ? "Logged in" : "Unregistered")
                        .font(.footnote)
                        .foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
                    Spacer()
                    Button(action:  tutorialContext.clearRegistrations)
                    {
                        Text("Clear")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 90.0, height: 42.0)
                            .background(Color.gray)
                    }
                }
            }
            VStack(spacing: 0.0) {
                Text("Call Settings")
                    .font(.largeTitle)
                    .padding(.top, 5)
                HStack {
                    Text("Call destination :")
                    TextField("", text : $tutorialContext.dest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.top, 5)
            }
            VStack(alignment: .leading) {
                Toggle(isOn: $tutorialContext.audioEnabled) {
                    Text("Audio")
                }.frame(width : 140.0)
                Toggle(isOn: $tutorialContext.videoEnabled) {
                    Text("Video")
                }.frame(width : 140.0)
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
                        Text(getCallButtonText())
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 180.0, height: 42.0)
                            .background(Color.green)
                    }
                    Button(action: tutorialContext.stopCall) {
                        Text("Stop Call")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 180.0, height: 42.0)
                            .background(Color.red)
                    }
                }
                HStack {
                    Text(callStateString())
                        .font(.footnote)
                        .foregroundColor(tutorialContext.callRunning || tutorialContext.isCallIncoming ? Color.green : Color.black)
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
        ContentView(tutorialContext: CallExampleContext())
    }
}
