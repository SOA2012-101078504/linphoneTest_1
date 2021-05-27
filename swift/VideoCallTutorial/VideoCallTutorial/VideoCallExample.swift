//
//  VideoCallExample.swift
//  VideoCallTutorial
//
//  Created by QuentinArguillere on 24/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw

class VideoCallExample : ObservableObject
{
	var mCore: Core! // We need a Core for... anything, basically
	@Published var coreVersion: String = Core.getVersion

	/*------------ Logs related variables ------------------------*/
	var loggingUnit = LoggingUnit()

	/*------------ Call tutorial related variables ---------------*/
	var mCall: Call!
	var mAccount : Account!
	var mVideoDevices : [String] = []
	var mUsedVideoDeviceId : Int = 0
	var callAlreadyStopped = false;

	@Published var videoEnabled : Bool = true
	@Published var callRunning : Bool = false
	@Published var isCallIncoming : Bool = false
	@Published var dest : String = "sip:calldest@sip.linphone.org"

	@Published var id : String = "sip:youraccount@sip.linphone.org"
	@Published var passwd : String = "yourpassword"
	@Published var loggedIn: Bool = false
	
	var mRegistrationDelegate : CoreDelegate!
	var mCallStateDelegate : CoreDelegate!
	
	init() {
		// Initialize Linphone Core
		try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

		// main loop for receiving notifications and doing background linphonecore work:
		mCore.autoIterateEnabled = true
		try? mCore.start()
		
		mVideoDevices = mCore.videoDevicesList
		
		// Callback for actions when a change in the RegistrationState of the Linphone Core happens
		mRegistrationDelegate = CoreDelegateStub(onRegistrationStateChanged: { (core: Core, proxyConfig: ProxyConfig, state: RegistrationState, message: String) in
			print("New registration state \(state) for user id \( String(describing: proxyConfig.identityAddress?.asString()))\n")
			if (state == .Ok) {
				self.loggedIn = true
				
			}
		})
		mCore.addDelegate(delegate: mRegistrationDelegate)
		
		// Callback for actions when a change in the CallState of the Linphone Core happens
		mCallStateDelegate = CoreDelegateStub(onCallStateChanged: { (lc: Core, call: Call, cstate: Call.State, message: String) in
			if (cstate == .IncomingReceived) {
				// We're being called by someone
				self.mCall = call
				self.isCallIncoming = true
			} else if (cstate == .OutgoingRinging) {
				// We're calling someone
				self.callRunning = true
			} else if (cstate == .StreamsRunning) {
				// Call has successfully began
				self.callRunning = true
			} else if (cstate == .End || cstate == .Error) {
				// Call has been terminated by any side, or an error occured
				self.callRunning = false
				self.isCallIncoming = false
			}
		})
		mCore.addDelegate(delegate: mCallStateDelegate)
	}
	
	func createProxyConfigAndRegister() {
		if (!loggedIn) {
			do {
				mAccount = try createAndInitializeAccount(core : mCore, identity: id, password: passwd)
				try mCore.addAccount(account: mAccount!)
				if ( mCore.defaultAccount == nil) {
					// IMPORTANT : default account setting MUST be done AFTER adding the config to the core !
					mCore.defaultAccount = mAccount
				}
			} catch {
				print(error)
			}
		}
	}
	
    func createCallParams() throws -> CallParams {
        let callParams = try mCore.createCallParams(call: nil)
        callParams.videoEnabled = videoEnabled;
        return callParams
    }
    
    // Initiate a call
    func outgoingCallExample() {
		mCore.videoActivationPolicy!.automaticallyAccept = videoEnabled
		mCore.videoActivationPolicy!.automaticallyInitiate = videoEnabled
        do {
            if (!callRunning) {
                let callDest = try Factory.Instance.createAddress(addr: dest)
                // Place an outgoing call
                mCall = try mCore.inviteAddressWithParams(addr: callDest, params: createCallParams())
                
                if (mCall == nil) {
                    print("Could not place call to \(dest)\n")
                } else {
                    print("Call to  \(dest) is in progress...")
                }
            }
            else {
                try mCall.update(params: createCallParams())
            }
        } catch { print(error) }
	}

	// Terminate a call
	func stopCall() {
		if ((callRunning || isCallIncoming) && mCall.state != Call.State.End) {
			callAlreadyStopped = true;
			// terminate the call
			print("Terminating the call...\n")
			do {
				try mCall.terminate()
			} catch
			{
				print(error)
			}
		}
	}

	func changeVideoDevice() {
		mUsedVideoDeviceId = (mUsedVideoDeviceId + 1) % mVideoDevices.count
		do {
			try mCore.setVideodevice(newValue: mVideoDevices[mUsedVideoDeviceId])
		} catch { print(error) }
	}
	
	func acceptCall() {
		do {
			try mCall.accept()
		} catch { print(error) }
	}
}
