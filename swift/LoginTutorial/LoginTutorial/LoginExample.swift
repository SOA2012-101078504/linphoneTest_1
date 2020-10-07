//
//  LoginExample.swift
//  LoginTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw

class LoginTutorialContext : ObservableObject
{
    var mCore: Core! // We need a Core for... anything, basically
    @Published var coreVersion: String = Core.getVersion
    
    /*------------ Logs related variables ------------------------*/
    var loggingUnit = LoggingUnit()
    
    /*------------ Login tutorial related variables -------*/
    var proxy_cfg: ProxyConfig?
    let mRegistrationDelegate = LinphoneRegistrationDelegate()
    @Published var id : String = "sip:myphonesip.linphone.org"
    @Published var passwd : String = "mypassword"
    @Published var loggedIn: Bool = false
    
    init()
    {
        // Initialize Linphone Core
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true
        try? mCore.start()
        
        mRegistrationDelegate.tutorialContext = self
        mCore.addDelegate(delegate: mRegistrationDelegate) // Add registration specific logs
    }
    
    func registrationExample()
    {
        if (!loggedIn)
        {
            do {
                if (proxy_cfg == nil) {
                    
                    proxy_cfg = try createAndInitializeProxyConfig(core : mCore, identity: id, password: passwd)
                    try mCore.addProxyConfig(config: proxy_cfg!)
                    if ( mCore.defaultProxyConfig == nil)
                    {
                        // IMPORTANT : default proxy config setting MUST be done AFTER adding the config to the core !
                        mCore.defaultProxyConfig = proxy_cfg
                    }
                }
                else {
                    proxy_cfg!.edit() /*start editing proxy configuration*/
                    proxy_cfg!.registerEnabled = true /*de-activate registration for this proxy config*/
                    try proxy_cfg!.done()
                }
            } catch {
                print(error)
            }
            
        }
    }

    func logoutExample()
    {
        if (loggedIn) {
            proxy_cfg!.edit() /*start editing proxy configuration*/
            proxy_cfg!.registerEnabled = false /*de-activate registration for this proxy config*/
            do {
                try proxy_cfg!.done()
            } catch {
                print(error)
            }
        }
    }

    
}


class LinphoneRegistrationDelegate: CoreDelegate {
    
    var tutorialContext : LoginTutorialContext!
	
	func onRegistrationStateChanged(core: Core, proxyConfig: ProxyConfig, state: RegistrationState, message: String) {
        print("New registration state \(state) for user id \( String(describing: proxyConfig.identityAddress?.asString()))\n")
        if (state == .Ok)
        {
            tutorialContext.loggedIn = true
        }
        else if (state == .Cleared)
        {
            tutorialContext.loggedIn = false
        }
    }
}
