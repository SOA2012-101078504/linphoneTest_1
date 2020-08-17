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
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
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
        
        // This is necessary to register to the server and handle push Notifications. Make sure you have a certificate to match your app's bundle ID.
        let pushConfig = mCore.pushNotificationConfig!
        pushConfig.provider = "apns.dev"
        
        try? mCore.start()
        
        // Callbacks on registration and call events
        mCallStateTracer.tutorialContext = self
        mRegistrationDelegate.tutorialContext = self
        mCore.addDelegate(delegate: mCallStateTracer)
        mCore.addDelegate(delegate: mRegistrationDelegate)
        
        // Available video devices that can be selected to be used in video calls
        mVideoDevices = mCore.videoDevicesList
    }
    
    
    func registrationExample()
    {
        if (!loggedIn)
        {
            do {
                proxy_cfg = try createAndInitializeProxyConfig(core : mCore, identity: id, password: passwd)
                proxy_cfg.pushNotificationAllowed = true
                try mCore.addProxyConfig(config: proxy_cfg!)
                if ( mCore.defaultProxyConfig == nil)
                {
                    // IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
                    mCore.defaultProxyConfig = proxy_cfg
                }
            } catch {
                print(error)
            }
            
        }
    }
    
    func clearRegistrations()
    {
        mCore.clearProxyConfig()
        loggedIn = false
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
        do {
            if (!callRunning)
            {
                mProviderDelegate.outgoingCall()
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
        if ((callRunning || isCallIncoming) && mCall.state != Call.State.End)
        {
            callAlreadyStopped = true;
            // terminate the call
            print("Terminating the call...\n")
            mProviderDelegate.stopCall()
        }
    }
    
    func speaker()
    {
        speakerEnabled = !speakerEnabled
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(speakerEnabled ? AVAudioSession.PortOverride.speaker : AVAudioSession.PortOverride.none )
        } catch {
            print(error)
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
    
}

// Callback for actions when a change in the Registration State happens
class LinphoneRegistrationDelegate: CoreDelegate {
    
    var tutorialContext : CallKitExampleContext!
    
    override func onRegistrationStateChanged(core lc: Core, proxyConfig cfg: ProxyConfig, state cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        if (cstate == .Ok)
        {
            tutorialContext.loggedIn = true
        }
    }
}


// Callback for actions when a change in the Call State happens
class CallStateDelegate: CoreDelegate {
    
    var tutorialContext : CallKitExampleContext!
    
    override func onCallStateChanged(core lc: Core, call: Call, state cstate: Call.State, message: String) {
        print("CallTrace - \(cstate)")
        
        let initIncomingCall = {
            self.tutorialContext.mCall = call
            self.tutorialContext.isCallIncoming = true
            self.tutorialContext.mProviderDelegate.incomingCall()
        }
        
        if (cstate == .PushIncomingReceived)
        {
            // We're being called by someone (and app is in background)
            initIncomingCall()
        }
        else if (cstate == .IncomingReceived && !tutorialContext.isCallIncoming) {
            // We're being called by someone (and app is in foreground, so call hasn't been initialized yet)
            initIncomingCall()
            
        } else if (cstate == .OutgoingRinging) {
            // We're calling someone
            tutorialContext.callRunning = true
        } else if (cstate == .End) {
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
