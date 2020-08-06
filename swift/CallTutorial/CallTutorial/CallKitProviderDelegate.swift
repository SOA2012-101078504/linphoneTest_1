//
//  ProviderDelegate.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 05/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import Foundation
import CallKit
import linphonesw
import AVFoundation


class CallKitProviderDelegate : NSObject
{
    private let provider: CXProvider
    let mCallController = CXCallController()
    var tutorialContext : CallExampleContext!
    
    init(context : CallExampleContext)
    {
        tutorialContext = context
        let providerConfiguration = CXProviderConfiguration(localizedName: Bundle.main.infoDictionary!["CFBundleName"] as! String)
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.generic]

        providerConfiguration.maximumCallsPerCallGroup = 10
        providerConfiguration.maximumCallGroups = 2
        
        provider = CXProvider(configuration: providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
        
    }
    
    func reportIncomingCall(call:Call?, uuid: UUID, handle: String, hasVideo: Bool) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type:.generic, value: handle)
        update.hasVideo = hasVideo
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            
        }
    }
    
    func outgoingCall(uuid : UUID)
    {
        let handle = CXHandle(type: .generic, value: "Outgoing Call")
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        mCallController.request(transaction, completion: { error in
            print("lalalalala")
        })
    }
    
}



extension CallKitProviderDelegate: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        tutorialContext.stopCall()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        tutorialContext.acceptCall()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {

    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        tutorialContext.outgoingCallExample()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
       
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
       
    }

    func providerDidReset(_ provider: CXProvider) {
        
    }
   
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        tutorialContext.mCore.activateAudioSession(actived: true)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        tutorialContext.mCore.activateAudioSession(actived: false)
    }
}
