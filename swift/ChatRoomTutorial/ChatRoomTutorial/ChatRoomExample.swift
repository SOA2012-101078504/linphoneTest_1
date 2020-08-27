//
//  ChatRoomExample.swift
//  ChatRoomTutorial
//
//  Created by QuentinArguillere on 04/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.

import linphonesw

enum ChatroomExampleState
{
    case Unstarted
    case Starting
    case Started
}

func toString(tutorialState state : ChatroomExampleState) -> String
{
    switch (state)
    {
        case ChatroomExampleState.Unstarted : return "Unstarted"
        case ChatroomExampleState.Starting: return "Starting"
        case ChatroomExampleState.Started: return "Started"
    }
}


class ChatRoomExampleContext : ObservableObject
{
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    /*------------ Logs related variables ------------------------*/
    var loggingUnit = LoggingUnit()
    
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
    @Published var chatroomAState = ChatroomExampleState.Unstarted
    
    /*---- Basic Chatroom tutorial related variables ----*/
    var mBasicChatRoom : ChatRoom?
    var mBasicChatroomProxyConfigRegistered : Bool = false
    @Published var basicChatRoomState = ChatroomExampleState.Unstarted
    
    
    init()
    {
        mChatRoomDelegate.tutorialContext = self
        mCoreChatDelegate.tutorialContext = self
        mRegistrationConfirmDelegate.tutorialContext = self
        
        // Initialize Linphone Core
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

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
                    , participants: chatDest)
                // Basic chatroom do not require setup time
                basicChatRoomState = ChatroomExampleState.Started
                
            }
            else if (!isBasicChatroom && mChatRoomA == nil)
            {
                chatParams.backend = ChatRoomBackend.FlexisipChat
                chatParams.encryptionEnabled = false
                chatParams.groupEnabled = false
                mChatRoomA = try mCore.createChatRoom(params: chatParams
                    , localAddr: mProxyConfigA.contact!
                    , participants: chatDest)
                    mChatRoomA!.addDelegate(delegate: mChatRoomDelegate)
                // Flexisip chatroom requires a setup time. The delegate will set the state to started when it is ready.
                    chatroomAState = ChatroomExampleState.Starting
            }
            
        } catch {
            print(error)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Wait until we're sure that the chatroom is ready to send messages
            while((isBasicChatroom ? self.basicChatRoomState : self.chatroomAState) != ChatroomExampleState.Started){
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

class LinphoneRegistrationConfirmDelegate: CoreDelegate {
    
    var tutorialContext : ChatRoomExampleContext!
    
    override func onRegistrationStateChanged(core lc: Core, proxyConfig cfg: ProxyConfig, state cstate: RegistrationState, message: String?) {
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

class LinphoneCoreChatDelegate: CoreDelegate {
    var tutorialContext : ChatRoomExampleContext!
	override func onMessageReceived(core lc: Core, chatRoom room: ChatRoom, message: ChatMessage) {
            
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
    
    var tutorialContext : ChatRoomExampleContext!
    
	override func onStateChanged(chatRoom cr: ChatRoom, newState: ChatRoom.State) {
        if (newState == ChatRoom.State.Created)
        {
            print("ChatRoomTrace - Chatroom ready to start")
            if (cr === tutorialContext.mChatRoomA)
            {
                tutorialContext.chatroomAState = ChatroomExampleState.Started
            }
            else if (cr === tutorialContext.mBasicChatRoom)
            {
                tutorialContext.basicChatRoomState = ChatroomExampleState.Started
            }
        }
    }
}

class LinphoneChatMessageTracker: ChatMessageDelegate {
	override func onMsgStateChanged(message msg: ChatMessage, state: ChatMessage.State) {
        print("MessageTrace - msg state changed: \(state)\n")
    }
}
