//
//  CallExample.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw
import AVFoundation

class CallKitExampleContext : ObservableObject
{
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    /*------------ Logs related variables ------------------------*/
    var loggingUnit = LoggingUnit()
    
    /*------------ Call tutorial related variables ---------------*/
    let mCallKitTutorialDelegate = CallKitTutorialDelegate()
    var mCall: Call!
    var account : Account!
    var mVideoDevices : [String] = []
    var mUsedVideoDeviceId : Int = 0
    var callAlreadyStopped = false;
    
    @Published var speakerEnabled : Bool = false
    @Published var callRunning : Bool = false
    @Published var isCallIncoming : Bool = false
    @Published var dest : String = "sip:calldest@sip.linphone.org"
    
    @Published var id : String = "sip:youraccount@sip.linphone.org"
    @Published var passwd : String = "yourpassword"
    @Published var loggedIn: Bool = false

    var mProviderDelegate : CallKitProviderDelegate!
    let outgoingCallName = "Outgoing call example"
    let incomingCallName = "Incoming call example"
    
    
    init()
    {
        mProviderDelegate = CallKitProviderDelegate(context : self)
        
        let factory = Factory.Instance // Instanciate
        // Initialize Linphone Core.
        // IMPORTANT : In this tutorial, we require the use of a core configuration file.
        // This way, once the registration is done, and until it is cleared, it will return to the LoggedIn state on launch.
        // This allows us to have a functional call when the app was closed and is started by a VOIP push notification (incoming call)
        let configDir = factory.getConfigDir(context: nil)
        try? mCore = factory.createCore(configPath: "\(configDir)/MyConfig", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
        mCore.callkitEnabled = true
        mCore.pushNotificationEnabled = true
        
        try? mCore.start()
        
        // Callbacks on registration and call events
		mCallKitTutorialDelegate.tutorialContext = self
        mCore.addDelegate(delegate: mCallKitTutorialDelegate)
    }
    
	func createAccountAndRegister() {
		if (!loggedIn) {
			do {
				account = try createAndInitializeAccount(core : mCore, identity: id, password: passwd)
				
				// This is necessary to register to the server and handle push Notifications. Make sure you have a certificate to match your app's bundle ID.
				let updatedPushParams = account.params?.clone()
				updatedPushParams?.pushNotificationConfig?.provider = "apns.dev"
				updatedPushParams?.pushNotificationAllowed = true
				account.params = updatedPushParams
				
				try mCore.addAccount(account: account!)
				if ( mCore.defaultAccount == nil) {
					// IMPORTANT : default account setting MUST be done AFTER adding the config to the core !
					mCore.defaultAccount = account
				}
			} catch {
				print(error)
			}

		}
	}
    
    func clearRegistrations()
    {
        mCore.clearAccounts()
        loggedIn = false
    }
    
    // Initiate a call
    func outgoingCallExample()
    {
        do {
            if (!callRunning) {
                mProviderDelegate.outgoingCall()
            }
            else {
                try mCall.update(params: mCore.createCallParams(call: nil))
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
            mProviderDelegate.stopCall()
        }
    }
}

// Callback for actions when a change in the Registration State happens
class CallKitTutorialDelegate: CoreDelegate {
    
    var tutorialContext : CallKitExampleContext!
	
	func onRegistrationStateChanged(core: Core, proxyConfig: ProxyConfig, state: RegistrationState, message: String) {
		print("New registration state \(state) for user id \( String(describing: proxyConfig.identityAddress?.asString()))\n")
		if (state == .Ok) {
			tutorialContext.loggedIn = true
		}
	}
	
	func onCallStateChanged(core lc: Core, call: Call, state cstate: Call.State, message: String) {
		print("CallTrace - \(cstate)")

		let initIncomingCall = {
			self.tutorialContext.mCall = call
			self.tutorialContext.isCallIncoming = true
			self.tutorialContext.mProviderDelegate.incomingCall()
		}

		if (cstate == .PushIncomingReceived){
			// We're being called by someone (and app is in background)
			initIncomingCall()
		}
		else if (cstate == .IncomingReceived && !tutorialContext.isCallIncoming) {
			// We're being called by someone (and app is in foreground, so call hasn't been initialized yet)
			initIncomingCall()
		} else if (cstate == .OutgoingRinging) {
			// We're calling someone
			tutorialContext.callRunning = true
		} else if (cstate == .End || cstate == .Error) {
			// Call has been terminated by any side
			if (!tutorialContext.callAlreadyStopped)
			{
				 // Report to CallKit that the call is over, if the terminate action was initiated by other end of the call
				 tutorialContext.mProviderDelegate.stopCall()
				 tutorialContext.callAlreadyStopped = false
			}
			tutorialContext.callRunning = false
			tutorialContext.isCallIncoming = false
		} else if (cstate == .StreamsRunning)
		{
			// Call has successfully began
			tutorialContext.callRunning = true
		}
	}
	
}
