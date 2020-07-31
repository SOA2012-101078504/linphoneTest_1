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
    let mPhoneStateTracer = LinconePhoneStateTracker()
    var mCall: Call!
    var mVideoDevices : [String] = []
    var mUsedVideoDeviceId : Int = 0
    
    @Published var audioEnabled : Bool = true
    @Published var videoEnabled : Bool = false
    @Published var speakerEnabled : Bool = false
    @Published var callRunning : Bool = false
    @Published var dest : String = "sip:arguillq@sip.linphone.org"
    

    init()
    {
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
                mCore.addDelegate(delegate: mPhoneStateTracer)
                
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
            mCore.removeDelegate(delegate: self.mPhoneStateTracer)
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


class LinconePhoneStateTracker: CoreDelegate {
    override func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        switch cstate {
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
    }
}
