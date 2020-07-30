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
    
    /*------------ Logs related variables ------------------------*/
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    @Published var logsEnabled : Bool = true
    
    /*------------ Registration tutorial related variables -------*/
    var proxy_cfg: ProxyConfig!
    let mRegistrationDelegate = LinphoneRegistrationDelegate()
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
    @Published var loggedIn: Bool = false
    
    
    /*------------ Call tutorial related variables ---------------*/
    let mPhoneStateTracer = LinconePhoneStateTracker()
    var call: Call!
    @Published var callRunning : Bool = false
    @Published var dest : String = "sip:arguillq@sip.linphone.org"
    
    
    /*--- Variable shared between Basic and FlexiSip chatrooms ----
      -------- "A" always initiates the chat, "B" answers --------*/
    let mIdA = "sip:peche5@sip.linphone.org", mIdB = "sip:jehan-iphone@sip.linphone.org"
    var mPasswordA = "peche5", mPasswordB = "cotcot"
    var mProxyConfigA, mProxyConfigB : ProxyConfig!
    var mChatMessage : ChatMessage?
    
    let mCoreChatDelegate = LinphoneCoreChatDelegate()
    let mChatMessageDelegate =  LinphoneChatMessageTracker()
    let mChatRoomDelegate = LinphoneChatRoomStateTracker()
    let mRegistrationConfirmDelegate = LinphoneRegistrationConfirmDelegate()
    
    @Published var proxyConfigARegistered : Bool = false
    @Published var proxyConfigBRegistered : Bool = false
    @Published var sLastReceivedMessage : String = ""
    
    
    /*---- FlexiSip Group Chatroom tutorial related variables ----*/
    let mFactoryUri = "sip:conference-factory@sip.linphone.org"
    var mChatRoomA, mChatRoomB : ChatRoom?
    @Published var chatroomAState = ChatroomTutorialState.Unstarted
    
    /*---- Basic Chatroom tutorial related variables ----*/
    var mBasicChatRoom : ChatRoom?
    var mBasicChatroomProxyConfigRegistered : Bool = false
    @Published var basicChatRoomState = ChatroomTutorialState.Unstarted
    
    
    init()
    {
        mChatRoomDelegate.tutorialContext = self
        mCoreChatDelegate.tutorialContext = self
        mRegistrationConfirmDelegate.tutorialContext = self
        
        let factory = Factory.Instance // Instanciate
        
        logManager = LinphoneLoggingServiceManager()
        logManager!.tutorialContext = self;
        log = LoggingService.Instance
        log!.addDelegate(delegate: logManager!)
        log!.logLevel = LogLevel.Debug
        factory.enableLogCollection(state: LogCollectionState.Enabled)
        
        // Initialize Linphone Core
        try? mCore = factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
        try? mCore.start()
        
        // Important ! Will notify when config are registered so that we can proceed with the chatroom creations
        mCore.addDelegate(delegate: mRegistrationConfirmDelegate)
        
        // Handle chat message reception
        mCore.addDelegate(delegate: mCoreChatDelegate)
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
    
    func registerChatRoomsProxyConfigurations()
    {
        mProxyConfigA = createProxyConfigAndRegister(identity : mIdA, password : mPasswordA, factoryUri: mFactoryUri)!
        mProxyConfigB = createProxyConfigAndRegister(identity : mIdB, password : mPasswordB, factoryUri: mFactoryUri)!
    }
    
    func createChatRoom(isBasic isBasicChatroom : Bool)
    {
        // proxy configuration must first be initialized and registered
        if (!proxyConfigARegistered || !proxyConfigBRegistered) { return }
        
        do {
            let chatDest = [mProxyConfigB.contact!]
            let chatParams = try mCore.createDefaultChatRoomParams()
            if (isBasicChatroom && mBasicChatRoom == nil)
            {
                chatParams.backend = ChatRoomBackend.Basic
                mBasicChatRoom = try mCore.createChatRoom(params: chatParams
                    , localAddr: mProxyConfigA.contact!
                    , subject: "Basic ChatRoom"
                    , participants: chatDest)
                basicChatRoomState = ChatroomTutorialState.Started
                
            }
            else if (!isBasicChatroom && mChatRoomA == nil)
            {
                chatParams.backend = ChatRoomBackend.FlexisipChat
                chatParams.encryptionEnabled = false
                chatParams.groupEnabled = false
                mChatRoomA = try mCore.createChatRoom(params: chatParams
                    , localAddr: mProxyConfigA.contact!
                    , subject: "Flexisip ChatRoom"
                    , participants: chatDest)
                    mChatRoomA!.addDelegate(delegate: mChatRoomDelegate)
                    chatroomAState = ChatroomTutorialState.Starting
            }
            
        } catch {
            print(error)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            while((isBasicChatroom ? self.basicChatRoomState : self.chatroomAState) != ChatroomTutorialState.Started){
                usleep(1000000)
            }
            
            if let chatRoom = (isBasicChatroom) ? self.mBasicChatRoom : self.mChatRoomA
            {
                do
                {
                    self.mChatMessage = try chatRoom.createMessage(message: "Hello, \((isBasicChatroom) ? "Basic" : "Flexisip") World !")
                    self.mChatMessage!.addDelegate(delegate: self.mChatMessageDelegate)
                    self.mChatMessage!.send()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func groupChatReply()
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
                HStack{
                    Button(action: tutorialContext.registerChatRoomsProxyConfigurations)
                    {
                        Text("Chat Login")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .frame(width: 190.0, height: 50.0)
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
                    VStack {
                        Button(action: { self.tutorialContext.createChatRoom(isBasic: true) })
                        {
                            Text("Basic Chat")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .frame(width: 170.0, height: 50.0)
                                .background(Color.gray)
                        }.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
                        HStack {
                            Text("Chatroom state : ")
                                .font(.footnote)
                            Text(toString(tutorialState: tutorialContext.basicChatRoomState))
                                .font(.footnote)
                                .foregroundColor((tutorialContext.basicChatRoomState == ChatroomTutorialState.Started) ? Color.green : Color.black)
                        }
                    }
                    VStack {
                        Button(action: { self.tutorialContext.createChatRoom(isBasic: false) })
                        {
                            Text("Flexisip Chat")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .frame(width: 200.0, height: 50.0)
                                .background(Color.gray)
                        }.disabled(!tutorialContext.proxyConfigBRegistered || !tutorialContext.proxyConfigBRegistered)
                        HStack {
                            Text("Chatroom state : ")
                                .font(.footnote)
                            Text(toString(tutorialState: tutorialContext.chatroomAState))
                                .font(.footnote)
                                .foregroundColor((tutorialContext.chatroomAState == ChatroomTutorialState.Started) ? Color.green : Color.black)
                        }
                    }
                }
                .padding(.top, 10.0)
                HStack {
                    Text("Last chat received :  \(tutorialContext.sLastReceivedMessage)")
                }.padding(.top, 30.0)
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

class LinphoneLoggingServiceManager: LoggingServiceDelegate {
    
    var tutorialContext : LinphoneTutorialContext!
    
    override func onLogMessageWritten(logService: LoggingService, domain: String, lev: LogLevel, message: String) {
        if (tutorialContext.logsEnabled)
        {
            print("Logging service log: \(message)s\n")
        }
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
            if (cfg === tutorialContext.mProxyConfigA)
            {
                tutorialContext.proxyConfigARegistered = true
            }
            else if (cfg === tutorialContext.mProxyConfigB)
            {
                tutorialContext.proxyConfigBRegistered = true
            }
            else if (cfg === tutorialContext.mBasicChatRoom)
            {
                tutorialContext.mBasicChatroomProxyConfigRegistered = true
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
            if (cr === tutorialContext.mChatRoomA)
            {
                tutorialContext.chatroomAState = ChatroomTutorialState.Started
            }
            else if (cr === tutorialContext.mBasicChatRoom)
            {
                tutorialContext.basicChatRoomState = ChatroomTutorialState.Started
            }
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
