//
//  CallExample.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw
import AVFoundation


struct DisplayableDevice : Identifiable {
	var id = UUID()
	var name : String
	
}

class CallExampleContext : ObservableObject
{
	var mCore: Core! // We need a Core for... anything, basically
	@Published var coreVersion: String = Core.getVersion

	/*------------ Logs related variables ------------------------*/
	var loggingUnit = LoggingUnit()

	/*------------ Call tutorial related variables ---------------*/
	let mCallTutorialDelegate = CallTutorialDelegate()
	var mCall: Call!
	var account : Account!
	var callAlreadyStopped = false;

	@Published var speakerEnabled : Bool = false
	@Published var microphoneMuted : Bool = false
	@Published var callRunning : Bool = false
	@Published var isCallIncoming : Bool = false
	@Published var dest : String = "sip:targetphone@sip.linphone.org"

	@Published var id : String = "sip:myphone@sip.linphone.org"
	@Published var passwd : String = "mypassword"
	@Published var loggedIn: Bool = false
	
	@Published var currentAudioDevice : AudioDevice!
	@Published var displayableDevices = [DisplayableDevice]()

	init() {
		mCallTutorialDelegate.tutorialContext = self

		// Initialize Linphone Core
		try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

		// main loop for receiving notifications and doing background linphonecore work:
		mCore.autoIterateEnabled = true
		try? mCore.start()

		currentAudioDevice = mCore.audioDevices[0]
		mCore.addDelegate(delegate: mCallTutorialDelegate)
	}

	func createAccountAndRegister() {
		if (!loggedIn) {
			do {
				account = try createAndInitializeAccount(core : mCore, identity: id, password: passwd)
				try mCore.addAccount(account: account!)
				if ( mCore.defaultAccount == nil) {
					// IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
					mCore.defaultAccount = account
				}
			} catch {
				print(error)
			}

		}
	}


	// Initiate a call
	func outgoingCallExample() {
		do {
			if (!callRunning)
			{
				let callDest = try Factory.Instance.createAddress(addr: dest)
				// Place an outgoing call
				mCall = mCore.inviteAddressWithParams(addr: callDest, params: try mCore.createCallParams(call: nil))

				if (mCall == nil) {
					print("Could not place call to \(dest)\n")
				} else {
					print("Call to  \(dest) is in progress...")
				}
			}
		} catch {
			print(error)
		}
	}
	
	// Terminate a call
	func stopCall() {
		if ((callRunning || isCallIncoming) && mCall.state != Call.State.End) {
			callAlreadyStopped = true;
			// terminate the call
			print("Terminating the call...\n")
			do {
				try mCall.terminate()
			} catch	{
				print(error)
			}
		}
	}
/*
	func updateAudioDevices() {
		var newDevices = [DisplayableDevice]()
		for device in mCore.audioDevices {
			newDevices.append(DisplayableDevice(name: device.deviceName))
		}
		displayableDevices = newDevices
		if let output = mCore.outputAudioDevice {
			currentAudioDevice = output
		}
	}
	func switchAudioOutput(newDevice: String) {
		for device in  mCore.audioDevices {
			if (newDevice == device.deviceName) {
				mCore.outputAudioDevice =  device
				currentAudioDevice = device
				break
			}
		}
	}*/
	
	func microphoneMuteToggle() {
		if (callRunning) {
			mCall.microphoneMuted = !mCall.microphoneMuted
			microphoneMuted = mCall.microphoneMuted
		}
	}

	func acceptCall()
	{
		do {
			try mCall.accept()
		} catch {
			print(error)
		}
	}
}

// Callback for actions when a change in the Registration State happens
class CallTutorialDelegate: CoreDelegate {

	var tutorialContext : CallExampleContext!
	
	func onRegistrationStateChanged(core: Core, proxyConfig: ProxyConfig, state: RegistrationState, message: String) {
		print("New registration state \(state) for user id \( String(describing: proxyConfig.identityAddress?.asString()))\n")
		if (state == .Ok) {
			tutorialContext.loggedIn = true
		}
	}
	
	func onCallStateChanged(core lc: Core, call: Call, state cstate: Call.State, message: String) {
		print("CallTrace - \(cstate)")
		if (cstate == .IncomingReceived) {
			// We're being called by someone
			tutorialContext.mCall = call
			tutorialContext.isCallIncoming = true
		} else if (cstate == .OutgoingRinging) {
			// We're calling someone
			tutorialContext.callRunning = true
		} else if (cstate == .StreamsRunning) {
			// Call has successfully began
			//tutorialContext.updateAudioDevices()
			tutorialContext.callRunning = true
		} else if (cstate == .End || cstate == .Error) {
			// Call has been terminated by any side, or an error occured
			tutorialContext.callRunning = false
			tutorialContext.isCallIncoming = false
		}
	}
	/*
	func onAudioDevicesListUpdated(core: Core) {
		tutorialContext.updateAudioDevices()
	}*/
	
}
