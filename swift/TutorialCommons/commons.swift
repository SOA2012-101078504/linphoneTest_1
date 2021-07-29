//  Created by QuentinArguillere on 17/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import Foundation
import linphonesw


func createAndInitializeAccount(core: Core, identity: String, password: String, withVoipPush: Bool = false, withRemotePush: Bool = false) throws -> Account {
	let factory = Factory.Instance
	let accountParams = try core.createAccountParams()
	let address = try factory.createAddress(addr: identity)
	let info = try factory.createAuthInfo(username: address.username, userid: "", passwd: password, ha1: "", realm: "", domain: address.domain)

	try accountParams.setIdentityaddress(newValue: address)
	try accountParams.setServeraddr(newValue: "sip:" + address.domain + ";transport=tls")
	accountParams.registerEnabled = true
	
	// This is necessary to register to the server and handle push Notifications. Make sure you have a certificate to match your app's bundle ID.
	accountParams.pushNotificationConfig?.provider = "apns.dev"
	
	accountParams.pushNotificationAllowed = withVoipPush
	accountParams.remotePushNotificationAllowed = withRemotePush
	core.addAuthInfo(info: info)
	return try core.createAccount(params: accountParams)
}


class LoggingUnit
{
	class BoolHolder : ObservableObject
	{
		@Published var value : Bool
		init(val : Bool) {
			value = val
		}
	}
	
	var logsEnabled : BoolHolder
	var logDelegate : LinphoneLoggingServiceImpl
	var log : LoggingService

	class LinphoneLoggingServiceImpl: LoggingServiceDelegate {
		var logsEnabled : BoolHolder!
		func onLogMessageWritten(logService: LoggingService, domain: String, level: LogLevel, message: String) {
			if (logsEnabled.value) {
				print("Linphone logs: \(message)")
			}
		}
	}

	init()
	{
		logsEnabled = BoolHolder(val: true)
		logDelegate = LinphoneLoggingServiceImpl()
		logDelegate.logsEnabled = logsEnabled;
		log = LoggingService.Instance
		log.addDelegate(delegate: logDelegate)
		log.logLevel = LogLevel.Debug
		Factory.Instance.enableLogCollection(state: LogCollectionState.Enabled)
	}
}
