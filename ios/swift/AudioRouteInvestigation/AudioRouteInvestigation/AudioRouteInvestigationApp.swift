//
//  AudioRouteInvestigationApp.swift
//  AudioRouteInvestigation
//
//  Created by QuentinArguillere on 25/11/2021.
//

import SwiftUI
import linphonesw

class AudioRouteInvestigation : ObservableObject
{
	var mCore: Core!
	var mCoreDelegate : CoreDelegate!
	
	/* PLEASE FILL THESE FIELDS WITH YOUR SETTINGS */
	var username : String = "user"
	var passwd : String = "password"
	var domain : String = "sip.linphone.org"
	var remoteAddress : String = "sip:remote@sip.linphone.org"
	
	@Published var loggedIn = false
	@Published var callMsg : String = ""
	@Published var isCallOutgoing : Bool = false
	@Published var isCallIncoming : Bool = false
	@Published var isCallRunning : Bool = false
	@Published var isCallPaused = false
	
	init() {
		LoggingService.Instance.logLevel = LogLevel.Debug
		try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
		
		//self.mCore.defaultOutputAudioDevice = self.mCore.audioDevices.first { $0.type == AudioDeviceType.Speaker }
		
		mCoreDelegate = CoreDelegateStub( onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
			self.callMsg = message
			
			if (state == .IncomingReceived) {
				self.isCallIncoming = true
			} else if (state == .OutgoingProgress) {
				self.isCallOutgoing = true
			} else if (state == .StreamsRunning) {
				self.isCallOutgoing = false
				self.isCallIncoming = false
				self.isCallRunning = true
				//self.mCore.outputAudioDevice = self.mCore.audioDevices.first { $0.type == AudioDeviceType.Speaker }
			} else if (state == .Released) {
				self.isCallOutgoing = false
				self.isCallIncoming = false
				self.isCallRunning = false
				self.isCallPaused = false
			}
		}, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
			NSLog("New registration state is \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
			if (state == .Ok) {
				self.loggedIn = true
			} else if (state == .Cleared) {
				self.loggedIn = false
			}
		})
		mCore.addDelegate(delegate: mCoreDelegate)
		
		
		try? mCore.start()
		login()
	}
	
	func login() {
		do {
			let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: passwd, ha1: "", realm: "", domain: domain)
			let accountParams = try mCore.createAccountParams()
			let identity = try Factory.Instance.createAddress(addr: String("sip:" + username + "@" + domain))
			try! accountParams.setIdentityaddress(newValue: identity)
			let address = try Factory.Instance.createAddress(addr: String("sip:" + domain))
			try address.setTransport(newValue: TransportType.Tls)
			try accountParams.setServeraddress(newValue: address)
			accountParams.registerEnabled = true
			let account = try mCore.createAccount(params: accountParams)
			mCore.addAuthInfo(info: authInfo)
			try mCore.addAccount(account: account)
			mCore.defaultAccount = account
		} catch { NSLog(error.localizedDescription) }
	}
	
	func outgoingCall() {
		do {
			let remoteAddress = try Factory.Instance.createAddress(addr: remoteAddress)
			let params = try mCore.createCallParams(call: nil)
			params.mediaEncryption = MediaEncryption.None
			
			
			//mCore.defaultOutputAudioDevice = mCore.audioDevices.first { $0.type == AudioDeviceType.Speaker }
			let call = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
			//call?.outputAudioDevice = mCore.audioDevices.first { $0.type == AudioDeviceType.Speaker }
			
		} catch { NSLog(error.localizedDescription) }
		
	}
	
	func incomingCall() {
		try? mCore.currentCall?.accept()
	}
	
	func terminateCall() {
		do {
			if (mCore.callsNb == 0) { return }
			let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
			if let call = coreCall {
				try call.terminate()
			}
		} catch { NSLog(error.localizedDescription) }
	}
	
	func pauseOrResume() {
		do {
			if (mCore.callsNb == 0) { return }
			let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
			
			if let call = coreCall {
				if (call.state != Call.State.Paused && call.state != Call.State.Pausing) {
					try call.pause()
					isCallPaused = true
				} else if (call.state != Call.State.Resuming) {
					try call.resume()
					isCallPaused = false
				}
			}
		} catch { NSLog(error.localizedDescription) }
	}
}


@main
struct AudioRouteInvestigationApp: App {
	
	@ObservedObject var audioRouteInvestigation = AudioRouteInvestigation()
	var body: some Scene {
		WindowGroup {
			ContentView(audioRouteInvestigation: audioRouteInvestigation)
		}
	}
}
