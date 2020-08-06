//
//  CallExample.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw
import AVFoundation

class CallExampleContext : ObservableObject
{
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    /*------------ Logs related variables ------------------------*/
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    @Published var logsEnabled : Bool = true
    
    /*------------ Call tutorial related variables ---------------*/
    let mCallStateTracer = CallStateDelegate()
    var mCall: Call!
    var mVideoDevices : [String] = []
    var mUsedVideoDeviceId : Int = 0
    
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
    
    @Published var enableCallKit = false;
    
    init()
    {
        mCallStateTracer.tutorialContext = self
        mRegistrationDelegate.tutorialContext = self
        
        let factory = Factory.Instance // Instanciate
        
        logManager = LinphoneLoggingServiceManager()
        logManager!.tutorialContext = self;
        log = LoggingService.Instance
        log!.addDelegate(delegate: logManager!)
        log!.logLevel = LogLevel.Debug
        factory.enableLogCollection(state: LogCollectionState.Enabled)
        
        // Initialize Linphone Core
        try? mCore = factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
        mCore.callkitEnabled = true
        try? mCore.start()
        
        mVideoDevices = mCore.videoDevicesList

        mCore.addDelegate(delegate: mCallStateTracer)
        mCore.addDelegate(delegate: mRegistrationDelegate)
        
        mProviderDelegate = CallKitProviderDelegate(context : self)
    }

    func registrationExample()
    {
        let factory = Factory.Instance
        do {
            let proxy_cfg = try mCore.createProxyConfig()
            let address = try factory.createAddress(addr: id)
            let info = try factory.createAuthInfo(username: address.username, userid: "", passwd: passwd, ha1: "", realm: "", domain: address.domain)
            mCore.addAuthInfo(info: info)
            
            try proxy_cfg.setIdentityaddress(newValue: address)
            let server_addr = "sip:" + address.domain + ";transport=tls"
            try proxy_cfg.setServeraddr(newValue: server_addr)
            proxy_cfg.registerEnabled = true
            try mCore.addProxyConfig(config: proxy_cfg)
            if ( mCore.defaultProxyConfig == nil)
            {
                // IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
                mCore.defaultProxyConfig = proxy_cfg
            }
            
        } catch {
            print(error)
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
        if ((callRunning || isCallIncoming) && mCall.state != Call.State.End)
        {
            // terminate the call
            print("Terminating the call...\n")
            do {
                if (enableCallKit)
                {
                    mProviderDelegate.stopCall()
                }
                else
                {
                    try mCall.terminate()
                }
            } catch {
                print(error)
            }
        }
    }
    
    func speaker()
    {
        speakerEnabled = !speakerEnabled
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(
                speakerEnabled ?
                AVAudioSession.PortOverride.speaker : AVAudioSession.PortOverride.none
            )
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
    
    var tutorialContext : CallExampleContext!
    
    override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        if (cstate == .Ok)
        {
            tutorialContext.loggedIn = true
        }
    }
}


class LinphoneLoggingServiceManager: LoggingServiceDelegate {
    
    var tutorialContext : CallExampleContext!
    
    override func onLogMessageWritten(logService: LoggingService, domain: String, lev: LogLevel, message: String) {
        if (tutorialContext.logsEnabled)
        {
            print("Logging service log: \(message)s\n")
        }
    }
}


// Callback for actions when a change in the Call State happens
class CallStateDelegate: CoreDelegate {
    
    var tutorialContext : CallExampleContext!
    
    override func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print("CallTrace - \(cstate)")
        if (cstate == .IncomingReceived) {
            // We're being called by someone
            tutorialContext.mCall = call
            tutorialContext.isCallIncoming = true
            if (tutorialContext.enableCallKit)
            {
                // Report the incoming call for CallKit
                tutorialContext.mProviderDelegate.incomingCall()
            }
            
        } else if (cstate == .OutgoingRinging) {
            // We're calling someone
            tutorialContext.callRunning = true
        } else if (cstate == .End) {
            // Call has been terminated by any side
            tutorialContext.callRunning = false
            tutorialContext.isCallIncoming = false;
            if (tutorialContext.enableCallKit)
            {
                // Report to CallKit that the call is over
                tutorialContext.mProviderDelegate.stopCall()
            }
        } else if (cstate == .StreamsRunning)
        {
            // Call has successfully began
            tutorialContext.callRunning = true
            tutorialContext.isCallIncoming = false
        }
    }
}
