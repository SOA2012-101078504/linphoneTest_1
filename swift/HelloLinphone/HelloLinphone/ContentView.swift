//
//  ContentView.swift
//  HelloLinphone
//
//  Created by Danmei Chen on 23/06/2020.
//  Copyright © 2020 belledonne. All rights reserved.
//

import linphonesw
import SwiftUI
import AVFoundation


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
    var mCall: Call!
    var mVideoDevices : [String] = []
    var mUsedVideoDeviceId : Int = 0
    
    @Published var audioEnabled : Bool = true
    @Published var videoEnabled : Bool = false
    @Published var speakerEnabled : Bool = false
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
    @Published var sLastReceivedText : String = ""
    @Published var sReplyText: String = ""
    
    
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
        
        mVideoDevices = mCore.videoDevicesList
        // Important ! Will notify when config are registered so that we can proceed with the chatroom creations
        mCore.addDelegate(delegate: mRegistrationConfirmDelegate)
        
        // Handle chat message reception
        mCore.addDelegate(delegate: mCoreChatDelegate)
        
        mVideoDevices = mCore.videoDevicesList
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
    func outgoingCallExample()
    {
        do {
            let callParams = try mCore.createCallParams(call: nil)
            callParams.videoEnabled = videoEnabled;
            callParams.audioEnabled = audioEnabled;
            
            if (!callRunning)
            {
                mCore.addDelegate(delegate: mPhoneStateTracer)
                
                let callDest = try Factory.Instance.createAddress(addr: dest)
                // Place an outgoing call
                mCall = mCore.inviteAddressWithParams(addr: callDest, params: callParams)
                
                if (mCall == nil) {
                    print("Could not place call to \(dest)\n")
                } else {
                    print("Call to  \(dest) is in progress...")
                    callRunning = true
                }
            }
            else
            {
                try mCall.update(params: callParams)
            }
        } catch {
            print(error)
        }
                
    }
    
    // Terminate a call
    func stopOutgoingCallExample()
    {
        if (callRunning)
        {
            callRunning = false
            if (mCall.state != Call.State.End){
                // terminate the call
                print("Terminating the call...\n")
                do {
                    try mCall.terminate()
                } catch {
                    callRunning = true
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
    
    func speaker()
    {
        speakerEnabled = !speakerEnabled
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(
                speakerEnabled ?
                AVAudioSession.PortOverride.speaker : AVAudioSession.PortOverride.none
            )
        } catch {
            print(error)
        }
    }
    
    func changeVideoDevice()
    {
        mUsedVideoDeviceId = (mUsedVideoDeviceId + 1) % mVideoDevices.count

        do {
            try mCore.setVideodevice(newValue: mVideoDevices[mUsedVideoDeviceId])
        } catch {
            print(error)
        }
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
                self.mChatMessage = try chatRoom.createMessage(message: sReplyText)
                self.mChatMessage!.send()
            } catch {
                print(error)
            }
        }
        else {
            sLastReceivedText = "Initialize chat first !"
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
            Spacer()
            VStack(spacing: 0.0) {
                Text("Call Settings")
                    .font(.largeTitle)
                HStack {
                    Text("Call destination :")
                    TextField("", text : $tutorialContext.dest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    VStack(alignment: .leading) {
                        Toggle(isOn: $tutorialContext.audioEnabled) {
                            Text("Audio")
                        }
                        Toggle(isOn: $tutorialContext.videoEnabled) {
                            Text("Video")
                        }
                        HStack {
                            Button(action: tutorialContext.changeVideoDevice)
                            {
                                Text("Change camera")
                                    .font(.title)
                                    .foregroundColor(Color.white)
                                    .background(Color.gray)
                            }
                            .padding(.bottom, 5.0)
                        }
                        HStack {
                            Text("Speaker :")
                            Spacer()
                            Button(action: tutorialContext.speaker)
                            {
                                Text(tutorialContext.speakerEnabled ? "ON" : "OFF")
                                    .font(.title)
                                    .foregroundColor(Color.white)
                                    .frame(width: 60.0, height: 30.0)
                                    .background(Color.gray)
                            }
                        }
                    }.frame(width : 160.0)
                    .padding(.top, 5.0)
                    Spacer()
                    VStack {
                        Button(action: tutorialContext.outgoingCallExample)
                        {
                            Text(tutorialContext.callRunning ? "Update Call" : "Call")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .frame(width: 180.0, height: 42.0)
                                .background(Color.green)
                        }
                        Button(action: tutorialContext.stopOutgoingCallExample) {
                            Text("Stop Call")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .frame(width: 180.0, height: 42.0)
                                .background(Color.red)
                        }
                        .padding(.top, 10.0)
                        HStack {
                            Text("Call State : ")
                                .font(.footnote)
                            Text(tutorialContext.callRunning ? "Ongoing" : "Stopped")
                                .font(.footnote)
                                .foregroundColor(tutorialContext.callRunning ? Color.green : Color.black)
                        }
                    }
                    .padding(.top, 10.0)
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
                                .frame(width: 200.0, height: 42.0)
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
                    Text("Last chat received :  \(tutorialContext.sLastReceivedText)")
                }.padding(.top, 30.0)
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
            tutorialContext.sLastReceivedText = message.textContent
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
