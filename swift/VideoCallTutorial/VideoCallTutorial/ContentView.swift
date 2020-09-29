//
//  ContentView.swift
//  VideoCallTutorial
//
//  Created by QuentinArguillere on 24/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI
import linphonesw

struct ContentView: View {
    
	@ObservedObject var tutorialContext : VideoCallExample
    
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
                    Text("Identity:")
                        .font(.subheadline)
                    TextField("", text : $tutorialContext.id)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Password:")
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
                    }.font(.footnote)
                    Text(tutorialContext.loggedIn ? "Logged in" : "Unregistered")
                        .font(.footnote)
                        .foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
                }
            }
			HStack {
				Text("Call dest:")
				TextField("", text : $tutorialContext.dest)
					.textFieldStyle(RoundedBorderTextFieldStyle())
			}
			HStack {
				Toggle(isOn: $tutorialContext.videoEnabled) {
                    Text("Video")
                }.frame(width : 110.0)
				Button(action: tutorialContext.changeVideoDevice)
                {
                    Text(" Change camera ")
                        .font(.title)
                        .foregroundColor(Color.white)
                        .background(Color.gray)
                }.padding(.leading)
			}
            VStack {
                HStack {
                    Button(action: {
                        if (self.tutorialContext.isCallIncoming) {
                            self.tutorialContext.acceptCall()
                        }
                        else {
                            self.tutorialContext.outgoingCallExample()
                        }
                    })
                    {
						
						Text(getCallButtonText())
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 180.0, height: 42.0)
                            .background(Color.green)
                    }
                    Button(action: tutorialContext.stopCall) {
                        Text(tutorialContext.isCallIncoming ? "Decline" : "Stop Call")
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

			HStack {
				Text("Audio Device :")
				Button(action: tutorialContext.changeAudioDevice)
				{
					Text("Change")
					.font(.title)
					.foregroundColor(Color.white)
					.frame(width: 110.0, height: 30.0)
					.background(Color.gray)
				}
			}.padding(.top)
			/*
			HStack {
				LinphoneVideoViewHolder()	{ view in
					self.tutorialContext.mCore.nativeVideoWindow = view
				}
				.frame(width: 150, height: 210)
				.border(Color.gray)
				.padding(.leading)
				Spacer()
				LinphoneVideoViewHolder()	{ view in
					self.tutorialContext.mCore.nativePreviewWindow = view
				}
				.frame(width: 90, height:  120)
				.border(Color.gray)
				.padding(.horizontal)
			}*/
            Group {
                Toggle(isOn: $tutorialContext.loggingUnit.logsEnabled.value) {
                    Text("Logs collection")
                        .multilineTextAlignment(.trailing)
                }
                Text("Core Version is \(tutorialContext.coreVersion)")
                    .font(.footnote)
            }
			EmptyView()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tutorialContext: VideoCallExample())
    }
}
