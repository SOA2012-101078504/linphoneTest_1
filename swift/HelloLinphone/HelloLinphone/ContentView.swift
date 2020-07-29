//
//  ContentView.swift
//  HelloLinphone
//
//  Created by Danmei Chen on 23/06/2020.
//  Copyright © 2020 belledonne. All rights reserved.
//

import linphonesw
import SwiftUI


enum ChatroomTutorialState
{
    case Unstarted
    case Starting
    case Started
}

func toString(tutorialState state : ChatroomTutorialState) -> String
{
    switch (state)
    {
        case ChatroomTutorialState.Unstarted : return "Unstarted"
        case ChatroomTutorialState.Starting: return "Starting"
        case ChatroomTutorialState.Started: return "Started"
    }
}


class LinphoneTutorialContext : ObservableObject
{
    var mCore: Core!
    var proxy_cfg: ProxyConfig!
    var call: Call!
    
    
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    
    
    let mRegistrationTracer = LinphoneRegistrationTracker()
    let mPhoneStateTracer = LinconePhoneStateTracker()
    let mChatRoomDelegate = LinphoneChatRoomStateTracker()
    let mChatMessageDelegate =  LinphoneChatMessageTracker()
    
    let mFactoryUri = "sip:conference-factory@sip.linphone.org"
    let mIdA = "sip:peche5@sip.linphone.org", mIdB = "sip:jehan-iphone@sip.linphone.org"
    var mPasswordA = "peche5", mPasswordB = "cotcot"
    var mProxyConfigA, mProxyConfigB : ProxyConfig!
    var mChatRoomA, mChatRoomB : ChatRoom?
    var mChatMessage : ChatMessage?
    
    @Published var coreVersion: String = Core.getVersion
    @Published var callRunning : Bool = false
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
    @Published var loggedIn: Bool = false
    @Published var dest : String = "sip:arguillq@sip.linphone.org"
    
    @Published var logsEnabled : Bool = true
    
    @Published var chatroomAState = ChatroomTutorialState.Unstarted
    @Published var chatroomBState = ChatroomTutorialState.Unstarted
    
    @Published var proxyConfigARegistered : Bool = false
    @Published var proxyConfigBRegistered : Bool = false
    
    
    init()
    {
        mRegistrationTracer.tutorialContext = self
        mChatRoomDelegate.tutorialContext = self
        
        let factory = Factory.Instance // Instanciate
        
        // set logsEnabled to false to disable logs collection
        if (logsEnabled)
        {
            log = LoggingService.Instance
            logManager = LinphoneLoggingServiceManager()
            log!.addDelegate(delegate: logManager!)
            log!.logLevel = LogLevel.Debug
            factory.enableLogCollection(state: LogCollectionState.Enabled)
        }
        
        // Initialize Linphone Core
        try? mCore = factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
        try? mCore.start()
        mCore.addDelegate(delegate: mRegistrationTracer) // Add registration specific logs
    }
    
    
    func createProxyConfigAndRegister(identity sId : String, password sPwd : String, factoryUri fUri : String) -> ProxyConfig?
    {
        let factory = Factory.Instance
        do {
            let proxy_cfg = try mCore.createProxyConfig()
            let address = try factory.createAddress(addr: sId)
            let info = try factory.createAuthInfo(username: address.username, userid: "", passwd: sPwd, ha1: "", realm: "", domain: address.domain)
            mCore.addAuthInfo(info: info)
            
            try proxy_cfg.setIdentityaddress(newValue: address)
            let server_addr = "sip:" + address.domain + ";transport=tls"
            try proxy_cfg.setServeraddr(newValue: server_addr)
            proxy_cfg.registerEnabled = true
            proxy_cfg.conferenceFactoryUri = fUri
            try mCore.addProxyConfig(config: proxy_cfg)
            if ( mCore.defaultProxyConfig == nil)
            {
                // IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
                mCore.defaultProxyConfig = proxy_cfg
            }
            return proxy_cfg
            
        } catch {
            loggedIn = false
            print(error)
        }
        return nil
    }
    
    func registrationExample()
    {
        proxy_cfg = createProxyConfigAndRegister(identity: id, password: passwd, factoryUri: "")
    }
    
    
    // Initiate a call
    func startOutgoingCallExample()
    {
        if (!callRunning)
        {
            mCore.addDelegate(delegate: mPhoneStateTracer)
            
            // Place an outgoing call
            call = mCore.invite(url: dest)
            
            if (call == nil) {
                print("Could not place call to \(dest)\n")
            } else {
                print("Call to  \(dest) is in progress...")
                callRunning = true
            }
        }
                
    }
    
    // Terminate a call
    func stopOutgoingCallExample()
    {
        if (callRunning)
        {
            if (call.state != Call.State.End){
                // terminate the call
                print("Terminating the call...\n")
                do {
                    try call.terminate()
                    callRunning = false
                } catch {
                    print(error)
                }
             }
            mCore.removeDelegate(delegate: self.mPhoneStateTracer)
        }
    }
    
    func virtualChatRoom()
    {
        mProxyConfigA = createProxyConfigAndRegister(identity : mIdA, password : mPasswordA, factoryUri: mFactoryUri)!
        mProxyConfigB = createProxyConfigAndRegister(identity : mIdB, password : mPasswordB, factoryUri: mFactoryUri)!
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            while(!self.proxyConfigARegistered || !self.proxyConfigBRegistered){
                usleep(1000000)
            }

            do {
                let chatParams = try self.mCore.createDefaultChatRoomParams()
                chatParams.backend = ChatRoomBackend.FlexisipChat
                chatParams.encryptionEnabled = false
                chatParams.groupEnabled = false
                self.mChatRoomA = try self.mCore.createChatRoom(params: chatParams
                    , localAddr: self.mProxyConfigA.contact!
                    , subject: "Tutorial ChatRoom"
                    , participants: [self.mProxyConfigB.contact!])
                self.mChatRoomA!.addDelegate(delegate: self.mChatRoomDelegate)
                
            } catch {
                print(error)
            }
        }

        self.chatroomAState = ChatroomTutorialState.Starting
        DispatchQueue.global(qos: .userInitiated).async {
            while(self.chatroomAState != ChatroomTutorialState.Started){
                usleep(1000000)
            }
            if let chatRoom = self.mChatRoomA
            {
                do
                {
                    self.mChatMessage = try chatRoom.createMessage(message: "This is my test message")
                    self.mChatMessage!.addDelegate(delegate: self.mChatMessageDelegate)
                    self.mChatMessage!.send()
                } catch {
                    print(error)
                }
            }
        }
        
    }
}



struct ContentView: View {
    
    @ObservedObject var tutorialContext = LinphoneTutorialContext()
    
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
                HStack {
                    Button(action:  tutorialContext.registrationExample)
                    {
                        Text("Login")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 100.0, height: 50.0)
                            .background(Color.gray)
                    }
                    Text(tutorialContext.loggedIn ? "Registered" : "")
                }
            }
            Spacer()
            VStack(spacing: 0.0) {
                Text("Call destination :")
                    .font(.largeTitle)
                TextField("", text : $tutorialContext.dest)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button(action: tutorialContext.startOutgoingCallExample)
                    {
                        Text("Call")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 130.0, height: 50.0)
                            .background(Color.green)
                    }
                    .padding(.trailing, 30.0)
                    Button(action: tutorialContext.stopOutgoingCallExample) {
                        Text("Stop Call")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 170.0, height: 50.0)
                            .background(Color.red)
                    }
                }
                .padding(.top, 15.0)
                HStack {
                    Text("Call State : ")
                    Text(tutorialContext.callRunning ? "Ongoing" : "Stopped")
                        .foregroundColor(tutorialContext.callRunning ? Color.green : Color.black)
                }
                .padding(.top, 5.0)
            }
            Spacer()
            Group {
                Button(action: tutorialContext.virtualChatRoom)
                {
                    Text("Simulate Chat")
                        .font(.largeTitle)
                        .foregroundColor(Color.white)
                        .frame(width: 230.0, height: 50.0)
                        .background(Color.green)
                }
                HStack {
                    Text("Chatroom state : ")
                    Text(toString(tutorialState: tutorialContext.chatroomAState))
                        .foregroundColor((tutorialContext.chatroomAState == ChatroomTutorialState.Started) ? Color.green : Color.black)
                }.padding(.top, 2.0)
            }
            Spacer()
            Text("Hello, Linphone, Core Version is \n \(tutorialContext.coreVersion)")
        }
        .padding()
    }
}

class LinphoneLoggingServiceManager: LoggingServiceDelegate {
    override func onLogMessageWritten(logService: LoggingService, domain: String, lev: LogLevel, message: String) {
        print("Logging service log: \(message)s\n")
    }
}

class LinphoneRegistrationTracker: CoreDelegate {
    
    var tutorialContext : LinphoneTutorialContext!
    
    override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        if (cstate == RegistrationState.Ok)
        {
            if let cfgIdentity = cfg.identityAddress
            {
                if (cfgIdentity.asString() == tutorialContext.mIdA)
                {
                    tutorialContext.proxyConfigARegistered = true
                }
                else if (cfgIdentity.asString() == tutorialContext.mIdB)
                {
                    tutorialContext.proxyConfigBRegistered = true
                }
            }
        }
    }
}

class LinconePhoneStateTracker: CoreDelegate {
    override func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        switch cstate {
        case .OutgoingRinging:
            print("CallTrace - It is now ringing remotely !\n")
        case .OutgoingEarlyMedia:
            print("CallTrace - Receiving some early media\n")
        case .Connected:
            print("CallTrace - We are connected !\n")
        case .StreamsRunning:
            print("CallTrace - Media streams established !\n")
        case .End:
            print("CallTrace - Call is terminated.\n")
        case .Error:
            print("CallTrace - Call failure !")
        default:
            print("CallTrace - Unhandled notification \(cstate)\n")
        }
    }
}

class LinphoneChatRoomStateTracker: ChatRoomDelegate {
    
    var tutorialContext : LinphoneTutorialContext!
    
    override func onStateChanged(cr: ChatRoom, newState: ChatRoom.State) {
        if (newState == ChatRoom.State.Created)
        {
            print("ChatRoomTrace - Chatroom ready to start")
            tutorialContext.chatroomAState = ChatroomTutorialState.Started
        }
    }
}

class LinphoneChatMessageTracker: ChatMessageDelegate {
    override func onMsgStateChanged(msg: ChatMessage, state: ChatMessage.State) {
        print("MessageTrace - msg state changed: \(state)\n")
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
