//FIXME GPL

//  Created by QuentinArguillere on 17/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import Foundation
import linphonesw

//FIXME expliquer
func createAndInitializeAccount(core: Core, identity: String, password: String, withVoipPush: Bool = false, withRemotePush: Bool = false) throws -> Account {
	let factory = Factory.Instance
	
	let accountParams = try core.createAccountParams()
	let address = try factory.createAddress(addr: identity)
	let info = try factory.createAuthInfo(username: address.username, userid: nil, passwd: password, ha1: nil, realm: nil, domain: address.domain)

	try accountParams.setIdentityaddress(newValue: address)
	try accountParams.setServeraddr(newValue: "sip:" + address.domain + ";transport=tcp")
	accountParams.registerEnabled = true
	
	// This is necessary to register to the server and handle push Notifications. Make sure you have a certificate to match your app's bundle ID.
	accountParams.pushNotificationConfig?.provider = "apns.dev"
	//FIXME + de coomtaires
	accountParams.pushNotificationAllowed = withVoipPush
	accountParams.remotePushNotificationAllowed = withRemotePush
	core.addAuthInfo(info: info)
	return try core.createAccount(params: accountParams)
}


class LoggingUnit
{

	var logsEnabled : Bool = true {
		didSet {
			LoggingService.Instance.logLevel = logsEnabled ? LogLevel.Debug: LogLevel.Fatal
		   }
	   }

	class LinphoneLoggingServiceImpl: LoggingServiceDelegate {
		func onLogMessageWritten(logService: LoggingService, domain: String, level: LogLevel, message: String) {
			print("Linphone logs: \(message)")
		}
	}

	init() 	{
		//FIXME commentaires
		LoggingService.Instance.addDelegate(delegate: LinphoneLoggingServiceImpl())
		LoggingService.Instance.logLevel = LogLevel.Debug
	}
}
