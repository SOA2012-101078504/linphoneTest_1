//
//  ContentView.swift
//  ChatRoomTutorial
//
//  Created by QuentinArguillere on 04/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
	@ObservedObject var tutorialContext : ChatRoomExampleContext
    
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
					Button(action:  tutorialContext.createProxyConfigAndRegister)
					{
						Text("Login")
						.font(.largeTitle)
						.foregroundColor(Color.white)
						.frame(width: 90.0, height: 42.0)
						.background(Color.gray)
					}
					Text("Login State : ")
					.font(.footnote)
					Text(tutorialContext.loggedIn ? "Logged in" : "Unregistered")
					.font(.footnote)
					.foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
				}
			}
			HStack {
				Text("Chat destination :")
				TextField("", text : $tutorialContext.dest)
				.textFieldStyle(RoundedBorderTextFieldStyle())
			}
			.padding(.top, 5)
			HStack {
				VStack() {
					Toggle(isOn: $tutorialContext.isFlexiSip) {
						Text("FlexiSip ChatRoom")
					}.frame(width: 210).padding(.top)

					HStack {
						Text("Chatroom state: ")
							.font(.footnote)
						Text(tutorialContext.getStateAsString())
							.font(.footnote)
							.foregroundColor((tutorialContext.chatroomState == ChatroomExampleState.Started) ? Color.green : Color.black)
					}
				}
				Button(action: {
					if (self.tutorialContext.chatroomState == ChatroomExampleState.Started) {
						self.tutorialContext.reset()
					} else {
						self.tutorialContext.createChatRoom()
					}
				})
				{
					Text((tutorialContext.chatroomState == ChatroomExampleState.Started) ? "Reset" : "Start\nChat")
						.font(.largeTitle)
					   .foregroundColor(Color.white)
					   .frame(width: 100.0, height: 82.0)
					   .background(Color.gray)
				}
			}
			HStack {
				VStack {
					Text("Chat received").bold()
					ScrollView {
						Text(tutorialContext.sReceivedMessages)
							.font(.footnote)
							.frame(width : 160)
					}.border(Color.gray)
					HStack {
						TextField("Sent text", text : $tutorialContext.textToSend)
							.textFieldStyle(RoundedBorderTextFieldStyle())
						Button(action: tutorialContext.sendMsg)
						{
							Text("Send")
								.font(.callout)
								.foregroundColor(Color.white)
								.frame(width: 50.0, height: 30.0)
								.background(Color.gray)
						}.disabled(tutorialContext.chatroomState != ChatroomExampleState.Started)
					}
				}
				Spacer()
			}.padding(.top)
			Group {
				Spacer()
				Toggle(isOn: $tutorialContext.loggingUnit.logsEnabled.value) {
					Text("Logs collection")
						.font(.body)
						.multilineTextAlignment(.trailing)
				}
				Text("Core Version is \(tutorialContext.coreVersion)")
			}
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tutorialContext: ChatRoomExampleContext())
    }
}
