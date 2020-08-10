//
//  ProviderDelegate.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 05/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import Foundation
import CallKit
import PushKit
import linphonesw
import AVFoundation


class CallKitProviderDelegate : NSObject
{
    private var voipRegistry: PKPushRegistry!
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

        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        
        provider = CXProvider(configuration: providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
        
    }
    
    func outgoingCall()
    {
        outgoingCallUUID = UUID()
        let handle = CXHandle(type: .generic, value: tutorialContext.outgoingCallName)
        let startCallAction = CXStartCallAction(call: outgoingCallUUID, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        provider.reportOutgoingCall(with: outgoingCallUUID, startedConnectingAt: nil)
        mCallController.request(transaction, completion: { error in })
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
        
        mCallController.request(transaction, completion: { error in })
    }
    
    func registerForVoIPPushes() {
        voipRegistry = PKPushRegistry(queue: nil)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
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

        do {
            let callDest = try Factory.Instance.createAddress(addr: tutorialContext.dest)
            // Place an outgoing call
            tutorialContext.mCall = tutorialContext.mCore.inviteAddressWithParams(addr: callDest, params: try tutorialContext.createCallParams())
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


extension CallKitProviderDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {

        let deviceTokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined() /*convert push tocken into hex string to be compliant with  flexisip format*/
        let aStr = String(format: "pn-provider=apns.dev;pn-prid=%@:voip;pn-param=Z2V957B3D6.org.linphone.tutorials.callkit.voip"
            ,deviceTokenString)

        tutorialContext.proxy_cfg.edit()
        tutorialContext.proxy_cfg.pushNotificationAllowed = true
        tutorialContext.proxy_cfg.contactUriParameters = aStr
        
        do {
            try tutorialContext.proxy_cfg.done()
        } catch {
            print(error)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        incomingCallUUID = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type:.generic, value: tutorialContext.incomingCallName)
        update.hasVideo = tutorialContext.videoEnabled
        
        provider.reportNewIncomingCall(with: incomingCallUUID, update: update, completion: { error in })
    }
}
