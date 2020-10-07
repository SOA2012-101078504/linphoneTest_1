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


class ChatRoomExampleContext : ObservableObject
{
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    /*------------ Logs related variables ------------------------*/
    var loggingUnit = LoggingUnit()
    
    /*-------- Chatroom tutorial related variables ---------------
      -------- "A" always initiates the chat, "B" answers --------*/
	
	
    let mFactoryUri = "sip:conference-factory@sip.linphone.org"
    var mProxyConfig : ProxyConfig!
    var mChatMessage : ChatMessage?
	let mLinphoneCoreDelegate = LinphoneCoreDelegate()
    let mChatMessageDelegate =  LinphoneChatMessageTracker()
    let mChatRoomDelegate = LinphoneChatRoomStateTracker()
    var mChatRoom : ChatRoom?
	
    @Published var chatroomState = ChatroomExampleState.Unstarted
    @Published var isFlexiSip : Bool = true
	@Published var textToSend: String = "msg to send"
    @Published var sReceivedMessages : String = ""
	@Published var dest : String = "sip:chatdest@sip.linphone.org"
	@Published var id : String = "sip:thisphone@sip.linphone.org"
	@Published var passwd : String = "mypassword"
	@Published var loggedIn: Bool = false
	
	//var fileFolderUrl : URL?
	//var fileUrl : URL?
	
	func getStateAsString() -> String
	{
		switch (chatroomState)
		{
			case ChatroomExampleState.Unstarted : return "Unstarted"
			case ChatroomExampleState.Starting: return "Starting"
			case ChatroomExampleState.Started: return "Started"
		}
	}
    
    init()
    {
        mChatRoomDelegate.tutorialContext = self
		mLinphoneCoreDelegate.tutorialContext = self
        
        // Initialize Linphone Core
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
        try? mCore.start()
        
        // Important ! Will notify when config are registered so that we can proceed with the chatroom creations
		// Also handles chat message reception
        mCore.addDelegate(delegate: mLinphoneCoreDelegate)
		
		/*
		let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
		let myFiles = documentsPath.appendingPathComponent("TutorialFiles")
		fileUrl = myFiles?.appendingPathComponent("file_to_transfer.txt")
		do{
			try FileManager.default.createDirectory(atPath: myFiles!.path, withIntermediateDirectories: true, attributes: nil)
			try String("My file content").write(to: fileUrl!, atomically: false, encoding: .utf8)
		}catch let error as NSError{
			print("Unable to create directory",error)
		}
		*/
    }
    
    func createProxyConfigAndRegister()
    {
        do {
			mProxyConfig = try createAndInitializeProxyConfig(core : mCore, identity: id, password: passwd)
			mProxyConfig.conferenceFactoryUri = mFactoryUri
			try mCore.addProxyConfig(config: mProxyConfig)
			if ( mCore.defaultProxyConfig == nil) {
				// IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
				mCore.defaultProxyConfig = mProxyConfig
			}
        } catch {
            print(error)
        }
    }
    
    func createChatRoom()
    {
        // proxy configuration must first be initialized and registered
        if (!loggedIn || mChatRoom != nil) { return }
        
        do {
			let chatDest = [try Factory.Instance.createAddress(addr: dest)]
            let chatParams = try mCore.createDefaultChatRoomParams()
            if (isFlexiSip) {
                chatParams.backend = ChatRoomBackend.FlexisipChat
                chatParams.encryptionEnabled = false
                chatParams.groupEnabled = false
				chatParams.subject = "Tutorial Chatroom"
                mChatRoom = try mCore.createChatRoom(params: chatParams, localAddr: mProxyConfig.contact!, participants: chatDest)
				mChatRoom!.addDelegate(delegate: mChatRoomDelegate)
                // Flexisip chatroom requires a setup time. The delegate will set the state to started when it is ready.
				chatroomState = ChatroomExampleState.Starting
            }
            else {
                chatParams.backend = ChatRoomBackend.Basic
                mChatRoom = try mCore.createChatRoom(params: chatParams, localAddr: mProxyConfig.contact!, participants: chatDest)
                // Basic chatroom do not require setup time
                chatroomState = ChatroomExampleState.Started
            }
        } catch {
            print(error)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Wait until we're sure that the chatroom is ready to send messages
			if (!self.isFlexiSip) {
				return
			}
			while(self.chatroomState != ChatroomExampleState.Started){
                usleep(100000)
            }
            
            if let chatRoom = self.mChatRoom
            {
                do
                {
					self.mChatMessage = try chatRoom.createMessage(message: "Hello, \((self.isFlexiSip) ? "Flexisip" : "Basic") World !")
                    self.mChatMessage!.addDelegate(delegate: self.mChatMessageDelegate)
                    self.mChatMessage!.send()
                } catch {
                    print(error)
                }
            }
        }
    }
    
	func send(room : ChatRoom, msg : String)
	{
		do
		{
			self.mChatMessage = try room.createMessage(message: msg)
			self.mChatMessage!.send()
		} catch {
			print(error)
		}
	}
	
    func sendMsg()
    {
        if let chatRoom = mChatRoom {
			send(room: chatRoom, msg: textToSend)
        }
    }
	/*
	func sendFile()
	{
		do {
			let content = try mCore.createContent()
			content.filePath = fileUrl!.absoluteString
			
			//mChatRoomA?.createFileTransferMessage(initialContent: <#T##Content#>)
			print(try String(contentsOf: fileUrl!, encoding: .utf8))
		}catch let error as NSError {
			print("Unable to create directory",error)
		}
	}*/
    
}

class LinphoneCoreDelegate: CoreDelegate {
    
    var tutorialContext : ChatRoomExampleContext!
	
	func onRegistrationStateChanged(core: Core, proxyConfig: ProxyConfig, state: RegistrationState, message: String) {
		print("New registration state \(state) for user id \( String(describing: proxyConfig.identityAddress?.asString()))\n")
        if (state == RegistrationState.Ok) {
			tutorialContext.loggedIn = true
		}
    }
	
	func onMessageReceived(core lc: Core, chatRoom room: ChatRoom, message: ChatMessage) {
		if (tutorialContext.mChatRoom == nil) {
			tutorialContext.mChatRoom = room
			tutorialContext.chatroomState = ChatroomExampleState.Started
		}
		if (message.contentType == "text/plain") {
			tutorialContext.sReceivedMessages += "\n\(message.textContent)"
		}
		print(message.contents.count)
	}
}

class LinphoneChatRoomStateTracker: ChatRoomDelegate {
    
    var tutorialContext : ChatRoomExampleContext!
    
	func onStateChanged(chatRoom cr: ChatRoom, newState: ChatRoom.State) {
        if (newState == ChatRoom.State.Created)
        {
			// This will only have sense when WE are creating a flexisip chatroom.
            print("ChatRoomTrace - Chatroom ready to start")
			tutorialContext.chatroomState = ChatroomExampleState.Started
        }
    }
}

class LinphoneChatMessageTracker: ChatMessageDelegate {
	func onMsgStateChanged(message msg: ChatMessage, state: ChatMessage.State) {
        print("MessageTrace - msg state changed: \(state)\n")
    }
}
