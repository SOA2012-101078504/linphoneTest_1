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
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    @Published var logsEnabled : Bool = true
    
    /*------------ Login tutorial related variables -------*/
    var proxy_cfg: ProxyConfig?
    let mRegistrationDelegate = LinphoneRegistrationDelegate()
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
    @Published var loggedIn: Bool = false
    
    init()
    {
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
        try? mCore.start()
        
        mCore.addDelegate(delegate: mRegistrationDelegate) // Add registration specific logs
    }
    
    func registrationExample()
    {
        if (!loggedIn)
        {
            
            do {
                
                if (proxy_cfg == nil) {
                    let factory = Factory.Instance
                    proxy_cfg = try mCore.createProxyConfig()
                    let address = try factory.createAddress(addr: id)
                    let info = try factory.createAuthInfo(username: address.username, userid: "", passwd: passwd, ha1: "", realm: "", domain: address.domain)
                    mCore.addAuthInfo(info: info)
                    
                    try proxy_cfg!.setIdentityaddress(newValue: address)
                    let server_addr = "sip:" + address.domain + ";transport=tls"
                    try proxy_cfg!.setServeraddr(newValue: server_addr)
                    proxy_cfg!.registerEnabled = true
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

class LinphoneLoggingServiceManager: LoggingServiceDelegate {
    
    var tutorialContext : LoginTutorialContext!
    
    override func onLogMessageWritten(logService: LoggingService, domain: String, lev: LogLevel, message: String) {
        if (tutorialContext.logsEnabled)
        {
            print("Logging service log: \(message)s\n")
        }
    }
}

class LinphoneRegistrationDelegate: CoreDelegate {
    
    var tutorialContext : LoginTutorialContext!
    
    override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String?) {
        print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        if (cstate == .Ok)
        {
            tutorialContext.loggedIn = true
        }
        else if (cstate == .Cleared)
        {
            tutorialContext.loggedIn = false
        }
    }
}
