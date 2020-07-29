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
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    
    /*---------------------------------- Logs related variables ---------------------------------------------*/
    let logsEnabled : Bool = true
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    
    
    /*-------------------------- Registration tutorial related variables ------------------------------------*/
    var proxy_cfg: ProxyConfig!
    let mRegistrationDelegate = LinphoneRegistrationDelegate()
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
    @Published var loggedIn: Bool = false
    
    
    
    /*--------------------------- Call tutorial related variables -------------------------------------------*/
    let mPhoneStateTracer = LinconePhoneStateTracker()
    var call: Call!
    @Published var callRunning : Bool = false
    @Published var dest : String = "sip:arguillq@sip.linphone.org"
    
    
    
    
    /*--------------------------- Chatroom tutorial related variables ---------------------------------------*/
    let mFactoryUri = "sip:conference-factory@sip.linphone.org"
    let mIdA = "sip:peche5@sip.linphone.org", mIdB = "sip:jehan-iphone@sip.linphone.org"
    var mPasswordA = "peche5", mPasswordB = "cotcot"
    var mProxyConfigA, mProxyConfigB : ProxyConfig!
    var mChatRoomA, mChatRoomB : ChatRoom?
    let mChatRoomDelegate = LinphoneChatRoomStateTracker()
    let mChatMessageDelegate =  LinphoneChatMessageTracker()
    let mCoreChatDelegate = LinphoneCoreChatDelegate()
    let mRegistrationConfirmDelegate = LinphoneRegistrationConfirmDelegate()
    var mChatMessage : ChatMessage?
    var proxyConfigARegistered : Bool = false
    var proxyConfigBRegistered : Bool = false
    
    
    @Published var chatroomAState = ChatroomTutorialState.Unstarted
    @Published var sLastReceivedMessage : String = ""
    
    
    init()
    {
        mChatRoomDelegate.tutorialContext = self
        mCoreChatDelegate.tutorialContext = self
        mRegistrationConfirmDelegate.tutorialContext = self
        
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
            print(error)
        }
        return nil
    }
    
    func registrationExample()
    {
        mCore.addDelegate(delegate: mRegistrationDelegate) // Add registration specific logs
        proxy_cfg = createProxyConfigAndRegister(identity: id, password: passwd, factoryUri: "")
        if (proxy_cfg != nil)
        {
            loggedIn = true
        }
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
        // Important ! Will notify when both config are registered so that we can proceed with the chatroom creation
        mCore.addDelegate(delegate: mRegistrationConfirmDelegate)
        
        // Handle message reception
        mCore.addDelegate(delegate: mCoreChatDelegate)
        
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
                    self.mChatMessage = try chatRoom.createMessage(message: "Hello, World !")
                    self.mChatMessage!.addDelegate(delegate: self.mChatMessageDelegate)
                    self.mChatMessage!.send()
                } catch {
                    print(error)
                }
            }
        }
        
    }
    
    
    func chatReply()
    {
        if let chatRoom = mChatRoomB {
            do
            {
                self.mChatMessage = try chatRoom.createMessage(message: "Reply")
                self.mChatMessage!.send()
            } catch {
                print(error)
            }
        }
        else {
            sLastReceivedMessage = "Initialize chat first !"
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
                VStack {
                    Button(action:  tutorialContext.registrationExample)
                    {
                        Text("Login")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 100.0, height: 50.0)
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
                        .font(.footnote)
                    Text(tutorialContext.callRunning ? "Ongoing" : "Stopped")
                        .font(.footnote)
                        .foregroundColor(tutorialContext.callRunning ? Color.green : Color.black)
                }
            }
            Spacer()
            Group {
                HStack {
                    Button(action: tutorialContext.virtualChatRoom)
                    {
                        Text("Initiate Chat")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 190.0, height: 50.0)
                            .background(Color.green)
                    }
                    Button(action: tutorialContext.chatReply)
                    {
                        Text("Reply")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 95.0, height: 50.0)
                            .background(Color.gray)
                    }
                }
                HStack {
                    Text("Chatroom state : ")
                        .font(.footnote)
                    Text(toString(tutorialState: tutorialContext.chatroomAState))
                        .font(.footnote)
                        .foregroundColor((tutorialContext.chatroomAState == ChatroomTutorialState.Started) ? Color.green : Color.black)
                }
                HStack {
                    Text("Last chat received :  \(tutorialContext.sLastReceivedMessage)")
                        .padding(.top, 5.0)
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

class LinphoneRegistrationDelegate: CoreDelegate {
    override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
    }
}

class LinphoneRegistrationConfirmDelegate: CoreDelegate {
    
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

class LinphoneCoreChatDelegate: CoreDelegate {
    var tutorialContext : LinphoneTutorialContext!
    override func onMessageReceived(lc: Core, room: ChatRoom, message: ChatMessage) {
            
        if (tutorialContext.mChatRoomB == nil)
        {
            tutorialContext.mChatRoomB = room
        }
        if (message.contentType == "text/plain")
        {
            tutorialContext.sLastReceivedMessage = message.textContent
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
