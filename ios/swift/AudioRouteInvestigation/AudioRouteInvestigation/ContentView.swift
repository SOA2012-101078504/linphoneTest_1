//
//  ContentView.swift
//  AudioRouteInvestigation
//
//  Created by QuentinArguillere on 25/11/2021.
//

import SwiftUI
import linphonesw

struct ContentView: View {
	
	@ObservedObject var audioRouteInvestigation : AudioRouteInvestigation
	
	func callStateString() -> String {
		if (audioRouteInvestigation.isCallOutgoing) {
			return "Call Outgoing"
		} else if (audioRouteInvestigation.isCallIncoming) {
			return "Call Incoming"
		} else if (audioRouteInvestigation.isCallRunning) {
			return "Call running"
		} else {
			return "No Call"
		}
	}
	
	var body: some View {
		
		VStack {
			VStack {
				HStack {
					Text(audioRouteInvestigation.username)
					Text(audioRouteInvestigation.loggedIn ? "REGISTERED" : "UNREGISTERED").foregroundColor(audioRouteInvestigation.loggedIn ? Color.green : Color.red)
				}
				Button(action: {
					if (self.audioRouteInvestigation.isCallIncoming) {
						self.audioRouteInvestigation.incomingCall()
					} else {
						self.audioRouteInvestigation.outgoingCall()
					}
				}){
					Text( self.audioRouteInvestigation.isCallIncoming ? "Accept Incoming Call" : "Start Outgoing Call")
						.font(.largeTitle)
						.foregroundColor(Color.white)
						.frame(width: 340.0, height: 45.0)
						.background(Color.gray)
				}.disabled(audioRouteInvestigation.isCallRunning)
				Button(action: audioRouteInvestigation.pauseOrResume) {
					Text(audioRouteInvestigation.isCallPaused ? "Resume call" : "Pause call")
						.font(.largeTitle)
						.foregroundColor(Color.white)
						.frame(width: 340.0, height: 42.0)
						.background(Color.gray)
				}.padding(.top, 50).disabled(!audioRouteInvestigation.isCallRunning)
				Button(action: audioRouteInvestigation.terminateCall) {
					Text( "Terminate call")
						.font(.largeTitle)
						.foregroundColor(Color.white)
						.frame(width: 340.0, height: 42.0)
						.background(Color.gray)
				}.padding(.top, 50).disabled(!audioRouteInvestigation.isCallRunning)
				HStack {
					Text("Call state: ").font(.title3).underline()
					Text(callStateString())
					Spacer()
				}
				HStack {
					Text("Current Call msg: ").font(.title3).underline()
					Text(audioRouteInvestigation.callMsg)
					Spacer()
				}.padding(.top, 50)
			}
		}
		.padding()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(audioRouteInvestigation: AudioRouteInvestigation())
	}
}
