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

    var incomingCallUUID : UUID!
    var outgoingCallUUID : UUID!
    
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
    
    func incomingCall() {
        incomingCallUUID = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type:.generic, value: tutorialContext.incomingCallName)
        update.hasVideo = tutorialContext.videoEnabled
        
        provider.reportNewIncomingCall(with: incomingCallUUID, update: update, completion: { error in })
    }
    
    func outgoingCall()
    {
        outgoingCallUUID = UUID()
        let handle = CXHandle(type: .generic, value: tutorialContext.outgoingCallName)
        let startCallAction = CXStartCallAction(call: outgoingCallUUID, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        mCallController.request(transaction, completion: { error in })
    }
    
    func stopCall()
    {
        let endCallAction = CXEndCallAction(call: incomingCallUUID)
        let transaction = CXTransaction(action: endCallAction)
        
        mCallController.request(transaction, completion: { error in })
    }
}



extension CallKitProviderDelegate: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if (tutorialContext.mCall.state != Call.State.End)
        {
            try? tutorialContext.mCall.terminate()
        }
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
