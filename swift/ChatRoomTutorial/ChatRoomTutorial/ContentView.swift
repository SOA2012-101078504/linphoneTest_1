//
//  ContentView.swift
//  ChatRoomTutorial
//
//  Created by QuentinArguillere on 04/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI

func getStateAsString(chatroomState : ChatroomExampleState) -> String
{
	switch (chatroomState)
	{
		case ChatroomExampleState.Unstarted : return "Unstarted"
		case ChatroomExampleState.Starting: return "Starting"
		case ChatroomExampleState.Started: return "Started"
	}
}

struct ActivityIndicator: UIViewRepresentable {
	func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView
	{
		return UIActivityIndicatorView(style: .medium)
	}
	
	func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>)
	{
		uiView.startAnimating()
	}
}

struct ContentView: View {
	
	@ObservedObject var tutorialContext : ChatRoomExampleContext
    
    var body: some View {
		NavigationView {
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
						Button(action:  tutorialContext.createAccountAndRegister)
						{
							Text("Login")
							.font(.largeTitle)
							.foregroundColor(Color.white)
							.frame(width: 90.0, height: 42.0)
							.background(Color.gray)
						}.disabled(tutorialContext.loggedIn)
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
				}.disabled(tutorialContext.chatroomState != ChatroomExampleState.Unstarted)
				.padding(.top, 5)
				HStack {
					VStack {
						Toggle(isOn: $tutorialContext.groupChatEnabled) {
							Text("Group ChatRoom")
						}.frame(width: 210)
						.padding(.top)
						.disabled(tutorialContext.chatroomState != ChatroomExampleState.Unstarted)
						Toggle(isOn: $tutorialContext.encryptionEnabled) {
							VStack {
								Text("Lime Encryption")
								Text("(group chat only)").italic().font(.footnote)
							}
						}.frame(width: 210)
						.disabled(tutorialContext.chatroomState != ChatroomExampleState.Unstarted)
						HStack {
							Text("Chatroom state: ")
								.font(.footnote)
							Text(getStateAsString(chatroomState: tutorialContext.chatroomState))
								.font(.footnote)
								.foregroundColor((tutorialContext.chatroomState == ChatroomExampleState.Started) ? Color.green : Color	.black)
							if (tutorialContext.chatroomState == ChatroomExampleState.Starting) {
								ActivityIndicator()
							}
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
							.frame(width: 140.0, height: 100.0)
							.background(Color.gray)
							.padding()
					}
				}
				Spacer()
				if (tutorialContext.chatroomState == ChatroomExampleState.Started)
				{
					NavigationLink(destination: Group{
						VStack {
							if (tutorialContext.mChatRoom!.canHandleParticipants()) {
								Text("Chat participants").bold()
								ScrollView {
									ForEach(tutorialContext.displayableUsers) { user in
										HStack {
											Text(user.name)
											Spacer()
											Button(action: { tutorialContext.removeParticipant(user: user) })
											{
												Text("Remove")
													.font(.callout)
													.foregroundColor(Color.white)
													.frame(width: 70.0, height: 35.0)
													.background(Color.gray)
											}
										}.padding(.horizontal).border(Color.gray)
									}.frame(height: 200)
								}.border(Color.gray)
								HStack {
									TextField("Add participant", text : $tutorialContext.newUser)
										.textFieldStyle(RoundedBorderTextFieldStyle())
									Button(action: tutorialContext.addParticipant)
									{
										Text("Add")
											.font(.callout)
											.foregroundColor(Color.white)
											.frame(width: 50.0, height: 30.0)
											.background(Color.gray)
									}
								}.padding()
							}
							Text("Chat received").bold()
							ScrollView {
								Text(tutorialContext.sReceivedMessages)
									.font(.footnote)
									.frame(width: 330, height: 400)
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
							HStack {
								Button(action: tutorialContext.sendExampleFile)
								{
									Text("Send example \n file")
									.foregroundColor(Color.white)
									.multilineTextAlignment(.center)
									.frame(width: 120.0, height: 50.0)
									.background(Color.gray)
								}.disabled(tutorialContext.chatroomState != ChatroomExampleState.Started)
								Button(action: tutorialContext.downloadLastFileMessage)
								{
									Text("Download last files \n received")
									.foregroundColor(Color.white)
									.multilineTextAlignment(.center)
									.frame(width: 150.0, height: 50.0)
									.background(Color.gray)
								}.disabled(tutorialContext.mLastFileMessageReceived == nil)
								if (tutorialContext.isDownloading) {
									ActivityIndicator()
								}
							}
						}
					})
					{
						HStack() {
							Spacer()
							Text("Go to chat view").multilineTextAlignment(.center).frame(width: 200, height: 100).foregroundColor(Color.white).background(Color.gray)
							Spacer()
						}
					}
					Group {
						Spacer()
						Toggle(isOn: $tutorialContext.loggingUnit.logsEnabled.value) {
							Text("Logs collection")
								.font(.body)
								.multilineTextAlignment(.trailing)
						}
						Text("Core Version is \(tutorialContext.coreVersion)")
					}
				}
			}.padding()
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tutorialContext: ChatRoomExampleContext())
    }
}