//
//  VideoCallExample.swift
//  VideoCallTutorial
//
//  Created by QuentinArguillere on 24/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw
import SwiftUI

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

	@Published var audioEnabled : Bool = true
	@Published var videoEnabled : Bool = false
	@Published var speakerEnabled : Bool = false
	@Published var callRunning : Bool = false
	@Published var isCallIncoming : Bool = false
	@Published var dest : String = "sip:arguillq@sip.linphone.org"

	let mRegistrationDelegate = LinphoneRegistrationDelegate()
	@Published var id : String = "sip:quentindev@sip.linphone.org"
	@Published var passwd : String = "dev"
	@Published var loggedIn: Bool = false

	/*--- Wrapper to incorporate the video chat view into a SwiftUI gui ---*/
	struct VideoView: UIViewRepresentable {
		let videoAsUIView = UIView()

		func makeUIView(context: Context) -> UIView {
			videoAsUIView.backgroundColor = .black
			return videoAsUIView
		}

		func updateUIView(_ uiView: UIView, context: Context) {}
	}
	let videoView = VideoView()
	
	
	init()
	{
		mCallStateTracer.tutorialContext = self
		mRegistrationDelegate.tutorialContext = self
	    // linphone_call_params_get_used_video_codec
		// Initialize Linphone Core
		try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

		// main loop for receiving notifications and doing background linphonecore work:
		mCore.autoIterateEnabled = true
		
		// Give the UIView in which the video will be rendered to the Linphone Core
		mCore.nativeVideoWindowId = UnsafeMutableRawPointer(Unmanaged.passRetained(videoView.videoAsUIView).toOpaque())
		try? mCore.start()
		
		mVideoDevices = mCore.videoDevicesList

		mCore.addDelegate(delegate: mCallStateTracer)
		mCore.addDelegate(delegate: mRegistrationDelegate)
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
        callParams.audioEnabled = audioEnabled;
        
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
    
    override func onRegistrationStateChanged(core lc: Core, proxyConfig cfg: ProxyConfig, state cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        if (cstate == .Ok) {
            tutorialContext.loggedIn = true
        }
    }
}


// Callback for actions when a change in the Call State happens
class CallStateDelegate: CoreDelegate {
    
    var tutorialContext : VideoCallExample!
    
    override func onCallStateChanged(core lc: Core, call: Call, state cstate: Call.State, message: String) {
        print("CallTrace - \(cstate)")
        if (cstate == .IncomingReceived) {
            // We're being called by someone
            tutorialContext.mCall = call
            tutorialContext.isCallIncoming = true
        } else if (cstate == .OutgoingRinging) {
            // We're calling someone
            tutorialContext.callRunning = true
        } else if (cstate == .End) {
            // Call has been terminated by any side
            tutorialContext.callRunning = false
            tutorialContext.isCallIncoming = false
        } else if (cstate == .StreamsRunning) {
            // Call has successfully began
            tutorialContext.callRunning = true
        }
    }
}
