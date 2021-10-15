//
//  LoginExample.swift
//  LoginTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//	

import linphonesw
var APP_GROUP_ID = "group.org.linphone.tutorials.notification"

class RemoteNotificationTutorialContext : ObservableObject
{
	var mCore: Core!
	@Published var coreVersion: String = Core.getVersion
	
	/*------------ Login tutorial related variables -------*/
	var mRegistrationDelegate : CoreDelegate!
	@Published var username : String = "user"
	@Published var passwd : String = "password"
	@Published var domain : String = "sip.example.org"
	@Published var loggedIn: Bool = false
	@Published var transportType : String = "TLS"
	
	init()
	{
		
		LoggingService.Instance.logLevel = LogLevel.Debug
		
		let config = Config.newForSharedCore(appGroupId: APP_GROUP_ID, configFilename: "linphonerc", factoryConfigFilename: "")!
		try? mCore = Factory.Instance.createSharedCoreWithConfig(config: config, systemContext: nil, appGroupId: APP_GROUP_ID, mainCore: true)
		mCore.pushNotificationEnabled = true
		// Core start/stop will be done in the scene delegate enter foreground/background
		
		mRegistrationDelegate = CoreDelegateStub(onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
			NSLog("New registration state is \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
			if (state == .Ok) {
				self.loggedIn = true
			} else if (state == .Cleared) {
				self.loggedIn = false
			}
		})
		mCore.addDelegate(delegate: mRegistrationDelegate)
	}
	
	func login() {
		
		do {
			var transport : TransportType
			if (transportType == "TLS") { transport = TransportType.Tls }
			else if (transportType == "TCP") { transport = TransportType.Tcp }
			else  { transport = TransportType.Udp }
			
			let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: passwd, ha1: "", realm: "", domain: domain)
			let accountParams = try mCore.createAccountParams()
			
			let identity = try Factory.Instance.createAddress(addr: String("sip:" + username + "@" + domain))
			try! accountParams.setIdentityaddress(newValue: identity)
			
			let address = try Factory.Instance.createAddress(addr: String("sip:" + domain))
			
			try address.setTransport(newValue: transport)
			try accountParams.setServeraddress(newValue: address)
			accountParams.registerEnabled = true
			
			// Set the provider to the development apple push notification servers, not the production ones.
			// Make sure your flexisip server has a matching certificate to send the pushes
			accountParams.pushNotificationConfig?.provider = "apns.dev"
			
			// We use remote notifications in this tutorials, not VOIP ones
			accountParams.pushNotificationAllowed = false
			accountParams.remotePushNotificationAllowed = true
			
			// We need a conference factory URI set on the Account to be able to create chat rooms with flexisip backend
			accountParams.conferenceFactoryUri = "sip:conference-factory@sip.linphone.org"
			
			let account = try mCore.createAccount(params: accountParams)
			
			mCore.addAuthInfo(info: authInfo)
			try mCore.addAccount(account: account)
			
			mCore.defaultAccount = account
			
		} catch { NSLog(error.localizedDescription) }
	}
	
	func unregister()
	{
		if let account = mCore.defaultAccount {
			let params = account.params
			let clonedParams = params?.clone()
			clonedParams?.registerEnabled = false
			account.params = clonedParams
		}
	}
	func delete() {
		if let account = mCore.defaultAccount {
			mCore.removeAccount(account: account)
			mCore.clearAccounts()
			mCore.clearAllAuthInfo()
		}
	}
}
