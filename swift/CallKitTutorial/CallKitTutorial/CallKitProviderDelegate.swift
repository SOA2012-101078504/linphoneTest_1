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
    var tutorialContext : CallKitExampleContext!

    var incomingCallUUID : UUID!
    var outgoingCallUUID : UUID!
    
    init(context: CallKitExampleContext)
    {
        tutorialContext = context
        let providerConfiguration = CXProviderConfiguration(localizedName: Bundle.main.infoDictionary!["CFBundleName"] as! String)
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.generic]

        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        
        provider = CXProvider(configuration: providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil) // The CXProvider delegate will trigger CallKit related callbacks
        
    }
    
    func outgoingCall()
    {
        outgoingCallUUID = UUID()
        let handle = CXHandle(type: .generic, value: tutorialContext.outgoingCallName)
        let startCallAction = CXStartCallAction(call: outgoingCallUUID, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        provider.reportOutgoingCall(with: outgoingCallUUID, startedConnectingAt: nil) // Report to CallKit a call is starting
        mCallController.request(transaction, completion: { error in })
    }

    func incomingCall()
    {
        incomingCallUUID = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type:.generic, value: tutorialContext.incomingCallName)
        
        provider.reportNewIncomingCall(with: incomingCallUUID, update: update, completion: { error in }) // Report to CallKit a call is incoming
    }
    
    func stopCall()
    {
        var callId = UUID();
        if (tutorialContext.isCallIncoming) {
            callId = incomingCallUUID
        } else if (tutorialContext.callRunning) {
            callId = outgoingCallUUID
        }
        let endCallAction = CXEndCallAction(call: callId)
        let transaction = CXTransaction(action: endCallAction)
        
        mCallController.request(transaction, completion: { error in }) // Report to CallKit a call is incoming
    }

}


// In this extension, we implement the action we want to be done when CallKit is notified of something.
// This can happen through the CallKit GUI in the app, or directly in the code (see outgoingCall(), incomingCall(), stopCall() functions above)
extension CallKitProviderDelegate: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if (tutorialContext.mCall.state != Call.State.End)
        {
            try? tutorialContext.mCall.terminate()
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        
        do {
            try tutorialContext.mCall.accept()
            tutorialContext.callRunning = true
        } catch {
            print(error)
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {

    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {

        do {
            let callDest = try Factory.Instance.createAddress(addr: tutorialContext.dest)
            // Place an outgoing call
            tutorialContext.mCall = tutorialContext.mCore.inviteAddressWithParams(addr: callDest, params: try tutorialContext.mCore.createCallParams(call: nil))
        } catch {
            print(error)
        }
        
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
