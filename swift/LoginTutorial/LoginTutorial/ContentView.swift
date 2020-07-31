//
//  ContentView.swift
//  LoginTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var tutorialContext = LoginTutorialContext()
    
    var body: some View {
        
        VStack {
            Group {
                HStack {
                    Text("Identity :")
                        .font(.title)
                    TextField("", text : $tutorialContext.id)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Password :")
                        .font(.title)
                    TextField("", text : $tutorialContext.passwd)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack {
                    Button(action:  tutorialContext.registrationExample)
                    {
                        Text("Login")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 100.0, height: 42.0)
                            .background(Color.gray)
                    }
                    HStack {
                        Text("Login State : ")
                            .font(.footnote)
                        Text(tutorialContext.loggedIn ? "Looged in" : "Unregistered")
                            .font(.footnote)
                            .foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
                    }
                }
            }
            Group {
                Spacer()
                Toggle(isOn: $tutorialContext.logsEnabled) {
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
        ContentView()
    }
}
