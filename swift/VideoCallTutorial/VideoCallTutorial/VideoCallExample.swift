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
	let mVideoTutorialDelegate = VideoTutorialDelegate()
	var mCall: Call!
	var proxy_cfg : ProxyConfig!
	var mVideoDevices : [String] = []
	var mUsedVideoDeviceId : Int = 0
	var callAlreadyStopped = false;

	@Published var videoEnabled : Bool = true
	@Published var callRunning : Bool = false
	@Published var isCallIncoming : Bool = false
	@Published var dest : String = "sip:targetphone@sip.linphone.org"

	@Published var id : String = "sip:myphone@sip.linphone.org"
	@Published var passwd : String = "mypassword"
	@Published var loggedIn: Bool = false
	
	init()
	{
		mVideoTutorialDelegate.tutorialContext = self
	    // linphone_call_params_get_used_video_codec
		// Initialize Linphone Core
		try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

		// main loop for receiving notifications and doing background linphonecore work:
		mCore.autoIterateEnabled = true
		try? mCore.start()
		
		mVideoDevices = mCore.videoDevicesList

		mCore.addDelegate(delegate: mVideoTutorialDelegate)
		
	}
	
	func registrationExample()
	{
		if (!loggedIn) {
			do {
				proxy_cfg = try createAndInitializeProxyConfig(core : mCore, identity: id, password: passwd)
				try mCore.addProxyConfig(config: proxy_cfg!)
				if ( mCore.defaultProxyConfig == nil) {
					// IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
					mCore.defaultProxyConfig = proxy_cfg
				}
			} catch {
				print(error)
			}
		}
	}
	
    func createCallParams() throws -> CallParams
    {
        let callParams = try mCore.createCallParams(call: nil)
        callParams.videoEnabled = videoEnabled;
        
        return callParams
    }
    
    // Initiate a call
    func outgoingCallExample()
    {
		mCore.videoActivationPolicy!.automaticallyAccept = videoEnabled
		mCore.videoActivationPolicy!.automaticallyInitiate = videoEnabled
        do {
            if (!callRunning)
            {
                let callDest = try Factory.Instance.createAddress(addr: dest)
                // Place an outgoing call
                mCall = mCore.inviteAddressWithParams(addr: callDest, params: try createCallParams())
                
                if (mCall == nil) {
                    print("Could not place call to \(dest)\n")
                } else {
                    print("Call to  \(dest) is in progress...")
                }
            }
            else
            {
                try mCall.update(params: createCallParams())
            }
        } catch {
            print(error)
        }
                
	}

	// Terminate a call
	func stopCall()
	{
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

	func changeVideoDevice()
	{
		mUsedVideoDeviceId = (mUsedVideoDeviceId + 1) % mVideoDevices.count
		let test = mVideoDevices[mUsedVideoDeviceId]
		do {
			try mCore.setVideodevice(newValue: mVideoDevices[mUsedVideoDeviceId])
		} catch {
			print(error)
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
class VideoTutorialDelegate: CoreDelegate {
    
    var tutorialContext : VideoCallExample!
	
	func onRegistrationStateChanged(core: Core, proxyConfig: ProxyConfig, state: RegistrationState, message: String) {
		print("New registration state \(state) for user id \( String(describing: proxyConfig.identityAddress?.asString()))\n")
		if (state == .Ok) {
			tutorialContext.loggedIn = true
		}
	}
	
	func onCallStateChanged(core lc: Core, call: Call, state cstate: Call.State, message: String) {
		if (cstate == .IncomingReceived) {
			// We're being called by someone
			tutorialContext.mCall = call
			tutorialContext.isCallIncoming = true
		} else if (cstate == .OutgoingRinging) {
			// We're calling someone
			tutorialContext.callRunning = true
		} else if (cstate == .StreamsRunning) {
			// Call has successfully began
			tutorialContext.callRunning = true
		} else if (cstate == .End || cstate == .Error) {
			// Call has been terminated by any side, or an error occured
			tutorialContext.callRunning = false
			tutorialContext.isCallIncoming = false
		}
	}

}
