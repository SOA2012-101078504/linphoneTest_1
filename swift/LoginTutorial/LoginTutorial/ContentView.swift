//
//  ContentView.swift
//  LoginTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
	@ObservedObject var tutorialContext : LoginTutorialContext
    
    var body: some View {
        
        VStack {
            Group {
                HStack {
                    Text("Identity :")
                        .font(.title)
                    TextField("", text : $tutorialContext.id)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
                }
                HStack {
                    Text("Password :")
                        .font(.title)
                    TextField("", text : $tutorialContext.passwd)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
                }
                VStack {
                    HStack {
                        Button(action:  {
                            if (self.tutorialContext.loggedIn)
                            {
                                self.tutorialContext.logoutExample()
                            } else {
                                self.tutorialContext.registrationExample()
                            }
                        })
                        {
                            Text(tutorialContext.loggedIn ? "Log out" : "Log in")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .frame(width: 125.0, height: 42.0)
                                .background(Color.gray)
                        }
                        
                    }
                    HStack {
                        Text("Login State : ")
                            .font(.footnote)
                        Text(tutorialContext.loggedIn ? "Looged in" : "Unregistered")
                            .font(.footnote)
                            .foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
                    }.padding(.top, 10.0)
                }
            }
            Group {
                Spacer()
                Toggle(isOn: $tutorialContext.loggingUnit.logsEnabled) {
                    Text("Logs collection")
                        .multilineTextAlignment(.trailing)
                }
                Text("Hello, Linphone, Core Version is \n \(tutorialContext.coreVersion)")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tutorialContext: LoginTutorialContext())
    }
}
