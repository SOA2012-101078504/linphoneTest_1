//  Created by QuentinArguillere on 17/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import Foundation
import linphonesw


func createAndInitializeProxyConfig(core: Core, identity: String, password: String) throws -> ProxyConfig {
	let factory = Factory.Instance
	let proxy_cfg = try core.createProxyConfig()
	let address = try factory.createAddress(addr: identity)
	let info = try factory.createAuthInfo(username: address.username, userid: "", passwd: password, ha1: "", realm: "", domain: address.domain)
	core.addAuthInfo(info: info)

	try proxy_cfg.setIdentityaddress(newValue: address)
	let server_addr = "sip:" + address.domain + ";transport=tls"
	try proxy_cfg.setServeraddr(newValue: server_addr)
	proxy_cfg.registerEnabled = true

	return proxy_cfg
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

	class LinphoneLoggingServiceImpl: LoggingServiceDelegate {
		var logsEnabled : BoolHolder!
		override func onLogMessageWritten(logService: LoggingService, domain: String, level: LogLevel, message: String) {
			if (logsEnabled.value) {
				print("Linphone logs: \(message)\n")
			}
		}
	}

	var logsEnabled : BoolHolder
	var logDelegate : LinphoneLoggingServiceImpl
	var log : LoggingService

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
