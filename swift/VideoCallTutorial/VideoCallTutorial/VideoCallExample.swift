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
	let mCallStateTracer = CallStateDelegate()
	var mCall: Call!
	var proxy_cfg : ProxyConfig!
	var mVideoDevices : [String] = []
	var mUsedVideoDeviceId : Int = 0
	var callAlreadyStopped = false;

	@Published var videoEnabled : Bool = true
	@Published var callRunning : Bool = false
	@Published var isCallIncoming : Bool = false
	@Published var dest : String = "sip:arguillq@sip.linphone.org"

	let mRegistrationDelegate = LinphoneRegistrationDelegate()
	@Published var id : String = "sip:quentindev@sip.linphone.org"
	@Published var passwd : String = "dev"
	@Published var loggedIn: Bool = false
	
	var audioDeviceId : Int = 0
	
	init()
	{
		mCallStateTracer.tutorialContext = self
		mRegistrationDelegate.tutorialContext = self
	    // linphone_call_params_get_used_video_codec
		// Initialize Linphone Core
		try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

		// main loop for receiving notifications and doing background linphonecore work:
		mCore.autoIterateEnabled = true
		
		try? mCore.start()
		
		mVideoDevices = mCore.videoDevicesList

		mCore.addDelegate(delegate: mCallStateTracer)
		mCore.addDelegate(delegate: mRegistrationDelegate)
		
	}
	func changeAudioDevice()
	{
		let devices = mCore.audioDevices
		audioDeviceId = (audioDeviceId + 1) % devices.count
		let previousDevice : String = mCore.outputAudioDevice!.deviceName
		let newDevice : String = devices[audioDeviceId].deviceName
		print("Core Device change : \(previousDevice) => \(newDevice)")
		
		var previousCallDevice : String = ""
		if (mCall != nil)	{
			previousCallDevice = mCall!.outputAudioDevice!.deviceName
		}
		mCore.outputAudioDevice = devices[audioDeviceId]
		
		if (mCall != nil){
			let newCallDevice : String = mCall!.outputAudioDevice!.deviceName
			print("Call Device change ? : \(previousCallDevice) => \(newCallDevice)")
		}
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
class LinphoneRegistrationDelegate: CoreDelegate {
    
    var tutorialContext : VideoCallExample!
    
	func onRegistrationStateChanged(core lc: Core, proxyConfig cfg: ProxyConfig, state cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        if (cstate == .Ok) {
            tutorialContext.loggedIn = true
        }
    }
	
	func onAudioDevicesListUpdated(core : Core) {
		print ("device list updated")
	}
}


// Callback for actions when a change in the Call State happens
class CallStateDelegate: CoreDelegate {
    
    var tutorialContext : VideoCallExample!
	
	func onCallStateChanged(core: Core, call: Call, state: Call.State, message: String) {
        print("CallTrace - \(state)")
        if (state == .IncomingReceived) {
            // We're being called by someone
            tutorialContext.mCall = call
            tutorialContext.isCallIncoming = true
        } else if (state == .OutgoingRinging) {
            // We're calling someone
            tutorialContext.callRunning = true
        } else if (state == .End) {
            // Call has been terminated by any side
            tutorialContext.callRunning = false
            tutorialContext.isCallIncoming = false
        } else if (state == .StreamsRunning) {
            // Call has successfully began
            tutorialContext.callRunning = true
        }
    }
}
