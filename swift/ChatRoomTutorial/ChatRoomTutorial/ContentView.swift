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
			HStack{
				Button(action: tutorialContext.registerChatRoomsProxyConfigurations)
				{
					Text("Chat Login")
						.font(.largeTitle)
						.foregroundColor(Color.white)
						.frame(width: 190.0, height: 42.0)
						.background(Color.gray)
				}.disabled(tutorialContext.proxyConfigBRegistered && tutorialContext.proxyConfigBRegistered)
				VStack{
					Text(tutorialContext.proxyConfigARegistered ? "A logged in" :"A not registered")
						.font(.footnote)
						.foregroundColor(tutorialContext.proxyConfigARegistered ? Color.green : Color.black)
					Text(tutorialContext.proxyConfigBRegistered ? "B logged in" :"B not registered")
						.font(.footnote)
						.foregroundColor(tutorialContext.proxyConfigBRegistered ? Color.green : Color.black)
				}
			}
			
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
				Button(action: { self.tutorialContext.createChatRoom() })
				{
					Text("Start\nChat")
						.font(.largeTitle)
					   .foregroundColor(Color.white)
					   .frame(width: 100.0, height: 82.0)
					   .background(Color.gray)
				}.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
			}
			HStack {
				VStack {
					Text("Chat received by A").bold()
					ScrollView {
						Text(tutorialContext.sReceivedMessagesA)
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
				VStack {
					Text("Chat received by B").bold()
					ScrollView {
						Text(tutorialContext.sReceivedMessagesB)
							.font(.footnote)
							.frame(width : 160)
					}.border(Color.gray)
					HStack {
						TextField("Reply text", text : $tutorialContext.sReplyText)
							.textFieldStyle(RoundedBorderTextFieldStyle())
						Button(action: tutorialContext.sendReply)
						{
							Text("Reply")
								.font(.callout)
								.foregroundColor(Color.white)
								.frame(width: 50.0, height: 30.0)
								.background(Color.gray)
						}.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
					}
				}
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
