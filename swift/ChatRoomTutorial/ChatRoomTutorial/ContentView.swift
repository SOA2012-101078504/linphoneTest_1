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
                
                VStack {
                    Button(action: { self.tutorialContext.createChatRoom(isBasic: true) })
                    {
                        Text("Basic Chat")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 170.0, height: 42.0)
                            .background(Color.gray)
                    }.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
                    HStack {
                        Text("Chatroom state: ")
                            .font(.footnote)
                        Text(toString(tutorialState: tutorialContext.basicChatRoomState))
                            .font(.footnote)
                            .foregroundColor((tutorialContext.basicChatRoomState == ChatroomExampleState.Started) ? Color.green : Color.black)
                    }
                }.padding(.top, 15)
                VStack {
                    Button(action: { self.tutorialContext.createChatRoom(isBasic: false) })
                    {
                        Text("Flexisip Chat")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 200.0, height: 42.0)
                            .background(Color.gray)
                    }.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
                    HStack {
                        Text("Chatroom state : ")
                            .font(.footnote)
                        Text(toString(tutorialState: tutorialContext.chatroomAState))
                            .font(.footnote)
                            .foregroundColor((tutorialContext.chatroomAState == ChatroomExampleState.Started) ? Color.green : Color.black)
                    }
                }.padding(.top, 15)
                HStack {
                    Text("Last chat received :  \(tutorialContext.sLastReceivedText)")
                }.padding(.top, 15)
                HStack {
                    Button(action: tutorialContext.groupChatReply)
                    {
                        Text("Chat reply")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 160.0, height: 42.0)
                            .background(Color.gray)
                    }.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
                    TextField("Reply text", text : $tutorialContext.sReplyText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }.padding(.top, 15)
            }
            Group {
                Spacer()
				Toggle(isOn: $tutorialContext.loggingUnit.logsEnabled.value) {
                    Text("Logs collection")
                        .multilineTextAlignment(.trailing)
                }
                Text("Hello, Linphone, Core Version is \n \(tutorialContext.coreVersion)")
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tutorialContext: ChatRoomExampleContext())
    }
}
