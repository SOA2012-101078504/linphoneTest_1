//
//  NotificationService.swift
//  notificationServiceAppExtension
//
//  Created by QuentinArguillere on 26/07/2021.
//

import UserNotifications
import linphonesw

var APP_GROUP_ID = "group.org.linphone.tutorials.notification"
var LINPHONE_DUMMY_SUBJECT = "dummy subject"

struct MsgData: Codable {
	var from: String?
	var body: String?
	var subtitle: String?
	var callId: String?
	var localAddr: String?
	var peerAddr: String?
}

class NotificationService: UNNotificationServiceExtension {
	
	var contentHandler: ((UNNotificationContent) -> Void)?
	var bestAttemptContent: UNMutableNotificationContent?
	
	var lc: Core?
	static var logDelegate: LinphoneLoggingServiceManager!
	static var log: LoggingService!
	
	func stopCore() {
		NotificationService.log.message(message: "stop core")
		if let lc = lc {
			lc.stop()
		}
	}

	
	// This function will be called when the app received a notification while in background // closed
	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		self.contentHandler = contentHandler
		bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
		NSLog("[notificationServiceAppExtension] start notificationServiceAppExtension")
		
		if let bestAttemptContent = bestAttemptContent {
			
			NSLog("[notificationServiceAppExtension] create core")
			let config = Config.newForSharedCore(appGroupId: APP_GROUP_ID, configFilename: "linphonerc", factoryConfigFilename: "")
			if (NotificationService.log == nil) {
				NotificationService.log = LoggingService.Instance /*enable liblinphone logs.*/
				NotificationService.logDelegate = try! LinphoneLoggingServiceManager(config: config!, log: NotificationService.log, domain: "notificationServiceAppExtension")
			}
			// We are creating a shared core, which will use the configuration file form the main app thanks to the App Group
			lc = try! Factory.Instance.createSharedCoreWithConfig(config: config!, systemContext: nil, appGroupId: APP_GROUP_ID, mainCore: false)
			NotificationService.log.message(message: "received push payload : \(bestAttemptContent.userInfo.debugDescription)")
			
			
			// Flexisip sends 2 types of remote push : invitation to a group chatroom, or receiving a chat message
			if let chatRoomInviteAddr = bestAttemptContent.userInfo["chat-room-addr"] as? String, !chatRoomInviteAddr.isEmpty {
				NotificationService.log.message(message: "fetch chat room for invite, addr: \(chatRoomInviteAddr)")
				
				// create a chatroom with the address we received
				let chatRoom = lc!.getNewChatRoomFromConfAddr(chatRoomAddr: chatRoomInviteAddr)
				
				if let chatRoom = chatRoom {
					stopCore()
					NotificationService.log.message(message: "chat room invite received")
					
					// Update notification body to display custom information
					bestAttemptContent.title = "You have been invited to a chatroom"
					if (chatRoom.hasCapability(mask:ChatRoomCapabilities.OneToOne.rawValue)) {
						if (chatRoom.peerAddress?.displayName.isEmpty != true) {
							bestAttemptContent.body = chatRoom.peerAddress!.displayName
						} else {
							bestAttemptContent.body = chatRoom.peerAddress!.username
						}
					} else {
						bestAttemptContent.body = chatRoom.subject
					}
					
					contentHandler(bestAttemptContent)
					return
				}
			} else if let callId = bestAttemptContent.userInfo["call-id"] as? String {
				NotificationService.log.message(message: "fetch msg for callid ["+callId+"]")
				// Get message content from the call id we received
				let message = lc!.getNewMessageFromCallid(callId: callId)
				
				if let message = message {
					
					func parseMessage(message: PushNotificationMessage) -> MsgData? {
						let content = message.isText ? message.textContent : "🗻"
						let fromAddr = message.fromAddr?.username
						let callId = message.callId
						let localUri = message.localAddr?.asStringUriOnly()
						let peerUri = message.peerAddr?.asStringUriOnly()
						var msgData = MsgData(from: fromAddr, body: "", subtitle: "", callId:callId, localAddr: localUri, peerAddr:peerUri)
						
						if let subject = message.subject as String?, subject != "" {
							msgData.subtitle = subject
							msgData.body = fromAddr! + " : " + content
						} else {
							msgData.subtitle = fromAddr
							msgData.body = content
						}
						
						NotificationService.log.message(message: "received msg size : \(content.count) \n")
						return msgData;
					}
					let msgData = parseMessage(message: message)
					
					stopCore()
					
					// Fill notification body with custom informations
					bestAttemptContent.title = "Message received"
					if let subtitle = msgData?.subtitle {
						bestAttemptContent.subtitle = subtitle
					}
					if let body = msgData?.body {
						bestAttemptContent.body = body
					}
					
					bestAttemptContent.userInfo.updateValue(msgData?.callId as Any, forKey: "CallId")
					bestAttemptContent.userInfo.updateValue(msgData?.from as Any, forKey: "from")
					bestAttemptContent.userInfo.updateValue(msgData?.peerAddr as Any, forKey: "peer_addr")
					bestAttemptContent.userInfo.updateValue(msgData?.localAddr as Any, forKey: "local_addr")
					
					contentHandler(bestAttemptContent)
					return
				} else {
					NotificationService.log.message(message: "Message not found for callid ["+callId+"]")
				}
			}
			serviceExtensionTimeWillExpire()
		}
	}
	
	override func serviceExtensionTimeWillExpire() {
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
		NotificationService.log.warning(message: "serviceExtensionTimeWillExpire")
		stopCore()
		if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
			NSLog("[notificationServiceAppExtension] serviceExtensionTimeWillExpire")
			
			if let chatRoomInviteAddr = bestAttemptContent.userInfo["chat-room-addr"] as? String, !chatRoomInviteAddr.isEmpty {
				bestAttemptContent.title = "You have been invited to a chatroom"
			} else {
				bestAttemptContent.title = "You have received a message"
			}
			contentHandler(bestAttemptContent)
		}
	}
	
}
