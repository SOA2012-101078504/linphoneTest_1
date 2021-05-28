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
    var account: Account?
	var mRegistrationDelegate : CoreDelegate!
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
		// Add callbacks to the Linphone Core
		mRegistrationDelegate = CoreDelegateStub(onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
			print("New registration state \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
			if (state == .Ok) {
				self.loggedIn = true
			} else if (state == .Cleared) {
				self.loggedIn = false
				
			}
		})
		mCore.addDelegate(delegate: mRegistrationDelegate)
    }
    
    func registrationExample()
    {
        if (!loggedIn) {
            do {
                if (account == nil) {
                    account = try createAndInitializeAccount(core : mCore, identity: id, password: passwd)
                    try mCore.addAccount(account: account!)
                    if ( mCore.defaultAccount == nil) {
						// IMPORTANT : default account setting MUST be done AFTER adding the config to the core !)
						mCore.defaultAccount = account
					}
                }
                else {
					let registeredParams = account?.params?.clone()
					registeredParams?.registerEnabled = false
					account?.params = registeredParams
				}
            } catch { print(error) }
        }
    }

    func logoutExample()
    {
        if (loggedIn) {
			let unregisteredParams = account?.params?.clone()
			unregisteredParams?.registerEnabled = false
			account?.params = unregisteredParams
        }
    }
    
}
