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


struct DisplayableUser : Identifiable {
	var id = UUID()
	var name : String
	
}

class ChatRoomExampleContext : ObservableObject {
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    /*------------ Logs related variables ------------------------*/
    var loggingUnit = LoggingUnit()
    
    /*-------- Chatroom tutorial related variables ---------------*/
	
	@Published var dest : String = "sip:arguillq@sip.linphone.org"
	@Published var id : String = "sip:quentindev@sip.linphone.org"
	@Published var passwd : String = "dev"
	@Published var loggedIn: Bool = false
	
    let mFactoryUri = "sip:conference-factory@sip.linphone.org"
    var mProxyConfig : ProxyConfig!
    var mChatMessage : ChatMessage?
	var mLastFileMessageReceived : ChatMessage?
	let mLinphoneCoreDelegate = LinphoneCoreDelegate()
    let mChatMessageDelegate =  LinphoneChatMessageTracker()
    let mChatRoomDelegate = LinphoneChatRoomStateTracker()
    var mChatRoom : ChatRoom?
	
	@Published var encryptionEnabled : Bool = false
	@Published var groupChatEnabled : Bool = true
    @Published var chatroomState = ChatroomExampleState.Unstarted
	@Published var textToSend: String = "Hello"
    @Published var sReceivedMessages : String = ""
	@Published var isDownloading : Bool = false
	
	@Published var displayableUsers = [DisplayableUser]()
	
	@Published var newUser : String = "sip:newuser@sip.linphone.org"
	var fileFolderUrl : URL?
	var fileUrl : URL?
    
	init() {

        mChatRoomDelegate.tutorialContext = self
		mLinphoneCoreDelegate.tutorialContext = self
		mChatMessageDelegate.tutorialContext = self
		
        // Initialize Linphone Core
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
		mCore.limeX3DhEnabled = true;
		mCore.limeX3DhServerUrl = "https://lime.linphone.org/lime-server/lime-server.php"
		mCore.fileTransferServer = "https://www.linphone.org:444/lft.php"
        try? mCore.start()
        
        // Important ! Will notify when config logged in, or when a message is received
        mCore.addDelegate(delegate: mLinphoneCoreDelegate)
		
		let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
		fileFolderUrl = documentsPath.appendingPathComponent("TutorialFiles")
		fileUrl = fileFolderUrl?.appendingPathComponent("file_to_transfer.txt")
		do{
			try FileManager.default.createDirectory(atPath: fileFolderUrl!.path, withIntermediateDirectories: true, attributes: nil)
			try String("My file content").write(to: fileUrl!, atomically: false, encoding: .utf8)
		}catch let error as NSError{
			print("Unable to create d)irectory",error)
		}
		
    }
    
    func createProxyConfigAndRegister() {
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
    
    func createChatRoom() {
        // proxy configuration must first be initialized and registered
        if (!loggedIn || mChatRoom != nil) { return }
        
        do {
			let chatDest = [try Factory.Instance.createAddress(addr: dest)]
            let chatParams = try mCore.createDefaultChatRoomParams()
            if (groupChatEnabled) {
                chatParams.backend = ChatRoomBackend.FlexisipChat
                chatParams.encryptionEnabled = encryptionEnabled
				if (encryptionEnabled) {
					chatParams.encryptionBackend = ChatRoomEncryptionBackend.Lime
				}
                chatParams.groupEnabled = groupChatEnabled
				chatParams.subject = "Tutorial Chatroom"
                mChatRoom = try mCore.createChatRoom(params: chatParams, localAddr: mProxyConfig.contact!, participants: chatDest)
                // Flexisip chatroom requires a setup time. The delegate will set the state to started when it is ready.
				chatroomState = ChatroomExampleState.Starting
				//displayableUsers.list.append(DisplayableUser(participant: mChatRoom!.participants[0]))
            }
            else {
                chatParams.backend = ChatRoomBackend.Basic
                mChatRoom = try mCore.createChatRoom(params: chatParams, localAddr: mProxyConfig.contact!, participants: chatDest)
                // Basic chatroom do not require setup time
                chatroomState = ChatroomExampleState.Started
            }
        } catch {
            print(error)
			return;
        }
		
		mChatRoom!.addDelegate(delegate: mChatRoomDelegate)
		
		
        DispatchQueue.global(qos: .userInitiated).async {
			if (self.groupChatEnabled) {
				// Wait until we're sure that the chatroom is ready to send messages
				while(self.chatroomState != ChatroomExampleState.Started){
					usleep(100000)
				}
			}
			if let chatRoom = self.mChatRoom {
				self.send(room: chatRoom, msg: "Hello, \((self.groupChatEnabled) ? "Group" : "") World !")
			}
        }
    }
	
	func reset() {
		if let chatRoom = mChatRoom {
			mCore.deleteChatRoom(chatRoom: chatRoom)
			mChatRoom = nil;
		}
		chatroomState = ChatroomExampleState.Unstarted
		displayableUsers = []
	}
	
	func send(room : ChatRoom, msg : String) {
		do
		{
			self.mChatMessage = try room.createMessageFromUtf8(message: msg)
			self.mChatMessage!.addDelegate(delegate: self.mChatMessageDelegate)
			self.mChatMessage!.send()
		} catch {
			print(error)
		}
	}
	
    func sendMsg() {
        if let chatRoom = mChatRoom {
			send(room: chatRoom, msg: textToSend)
        }
    }
	
	func sendExampleFile() {
		do {
			let content = try mCore.createContent()
			content.filePath = fileUrl!.path
			content.name = "file_to_transfer.txt"
			content.type = "text"
			content.subtype = "plain"
			
			mChatMessage = try mChatRoom!.createFileTransferMessage(initialContent: content)
			mChatMessage!.send()
		}catch let error as NSError {
			print("Unable to create directory",error)
		}
	}
	
	func downloadLastFileMessage() {
		if let message = mLastFileMessageReceived {
			for content in message.contents {
				if (content.isFileTransfer && content.filePath.isEmpty) {
					let contentName = content.name
					if (!contentName.isEmpty) {
						content.filePath = fileFolderUrl!.appendingPathComponent(contentName).path
						print("Start downloading \(content.name) into \(content.filePath)")
						isDownloading = true
						if (!message.downloadContent(content: content)) {
							print ("Download of \(contentName) failed")
						}
					}
				}
			}
		}
	}
	
	func addParticipant() {
		if let chatroom = mChatRoom {
			do {
				chatroom.addParticipant(addr: try Factory.Instance.createAddress(addr: newUser))
				displayableUsers.append(DisplayableUser(name: newUser))
			} catch let error as NSError {
				print("Unable to create directory",error)
			}
		}
	}
	
	func removeParticipant(user : DisplayableUser) {
		
		if let userAddr = try? Factory.Instance.createAddress(addr: user.name) {
			for part in mChatRoom!.participants {
				if (part.address!.equal(address2: userAddr))
				{
					mChatRoom!.removeParticipant(participant: part)
				}
			}
		}
		
		for i in 0...displayableUsers.count {
			if (displayableUsers[i].id == user.id) {
				displayableUsers.remove(at: i)
				break
			}
		}
		
	}
    
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
		
		if (message.hasTextContent()) {
			tutorialContext.sReceivedMessages += "\n\(message.utf8Text)"
		}
		
		for content in message.contents {
			if (content.isFileTransfer) {
				tutorialContext.mLastFileMessageReceived = message
				tutorialContext.sReceivedMessages += "\n File(s) available(s) for download"
				break;
			}
		}
	}
}

class LinphoneChatRoomStateTracker: ChatRoomDelegate {
    var tutorialContext : ChatRoomExampleContext!
	
	func onConferenceJoined(chatRoom: ChatRoom, eventLog: EventLog) {
		print("ChatRoomTrace - Chatroom ready to start")
		tutorialContext.displayableUsers = []
		for part in chatRoom.participants {
			tutorialContext.displayableUsers.append(DisplayableUser(name: part.address!.asString()))
		}
		tutorialContext.chatroomState = ChatroomExampleState.Started
	}
}

class LinphoneChatMessageTracker: ChatMessageDelegate {
	var tutorialContext : ChatRoomExampleContext!
	
	func onMsgStateChanged(message msg: ChatMessage, state: ChatMessage.State) {
        print("MessageTrace - msg state changed: \(state)\n")
		if (state == ChatMessage.State.FileTransferDone && tutorialContext.isDownloading == true) {
			tutorialContext.isDownloading = false
		}
    }
}
