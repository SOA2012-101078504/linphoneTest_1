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
    @Published var dest : String = "sip:arguillq@sip.linphone.org"
    
    
    var proxy_cfg: ProxyConfig!
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
    @Published var loggedIn: Bool = false
    

    init()
    {
        mCallStateTracer.tutorialContext = self
        
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
        try? mCore.start()
        
        mVideoDevices = mCore.videoDevicesList
     
        registrationExample()
        mCore.addDelegate(delegate: mCallStateTracer)
    }
    
    // Initiate a call
    func outgoingCallExample()
    {
        do {
            let callParams = try mCore.createCallParams(call: nil)
            callParams.videoEnabled = videoEnabled;
            callParams.audioEnabled = audioEnabled;
            
            if (!callRunning)
            {
                let callDest = try Factory.Instance.createAddress(addr: dest)
                // Place an outgoing call
                mCall = mCore.inviteAddressWithParams(addr: callDest, params: callParams)
                
                if (mCall == nil) {
                    print("Could not place call to \(dest)\n")
                } else {
                    print("Call to  \(dest) is in progress...")
                    callRunning = true
                }
            }
            else
            {
                try mCall.update(params: callParams)
            }
        } catch {
            print(error)
        }
                
    }
    
    // Terminate a call
    func stopOutgoingCallExample()
    {
        if (callRunning)
        {
            callRunning = false
            if (mCall.state != Call.State.End){
                // terminate the call
                print("Terminating the call...\n")
                do {
                    try mCall.terminate()
                } catch {
                    callRunning = true
                    print(error)
                }
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
    
    /*
    func acceptCall(incomingCall call : Call)
    {
        mCall = call
        do {
            try call.accept()
        } catch {
            print(error)
        }
    }
    */
    
    func createProxyConfigAndRegister(identity sId : String, password sPwd : String, factoryUri fUri : String) -> ProxyConfig?
    {
        let factory = Factory.Instance
        do {
            let proxy_cfg = try mCore.createProxyConfig()
            let address = try factory.createAddress(addr: sId)
            let info = try factory.createAuthInfo(username: address.username, userid: "", passwd: sPwd, ha1: "", realm: "", domain: address.domain)
            mCore.addAuthInfo(info: info)
            
            try proxy_cfg.setIdentityaddress(newValue: address)
            let server_addr = "sip:" + address.domain + ";transport=tls"
            try proxy_cfg.setServeraddr(newValue: server_addr)
            proxy_cfg.registerEnabled = true
            proxy_cfg.conferenceFactoryUri = fUri
            try mCore.addProxyConfig(config: proxy_cfg)
            if ( mCore.defaultProxyConfig == nil)
            {
                // IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
                mCore.defaultProxyConfig = proxy_cfg
            }
            return proxy_cfg
            
        } catch {
            print(error)
        }
        return nil
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
            loggedIn = true
            
        } catch {
            print(error)
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


class CallStateDelegate: CoreDelegate {
    
    var tutorialContext : CallExampleContext!
    
    override func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print("CallTrace - \(cstate)")
        /*
        let traceFn = { print("CallTrace - \(cstate)") }
        switch cstate
        {
            case .IncomingReceived:
                tutorialContext.acceptCall(incomingCall: call)
            case .IncomingEarlyMedia:
                traceFn()
            case .PushIncomingReceived:
                traceFn()
            case .OutgoingRinging:
                print("CallTrace - It is now ringing remotely !\n")
            case .OutgoingEarlyMedia:
                print("CallTrace - Receiving some early media\n")
            case .Connected:
                print("CallTrace - We are connected !\n")
            case .StreamsRunning:
                print("CallTrace - Media streams established !\n")
            case .End:
                print("CallTrace - Call is terminated.\n")
            case .Error:
                print("CallTrace - Call failure !")
            default:
                print("CallTrace - Unhandled notification \(cstate)\n")
        }
 */
    }
}
