//
//  SceneDelegate.swift
//  HelloLinphone
//
//  Created by Danmei Chen on 23/06/2020.
//  Copyright © 2020 belledonne. All rights reserved.
//

import UIKit
import SwiftUI
import linphonesw

let DEBUG_LOGS : Bool = false;

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	var mCore: Core!
    var proxy_cfg: ProxyConfig!
    let mRegistrationTrace = LinphoneRegistrationTracer()
    
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    
    class LinphoneLoggingServiceManager: LoggingServiceDelegate {
        override func onLogMessageWritten(logService: LoggingService, domain: String, lev: LogLevel, message: String) {
            print("Logging service log: \(message)s\n")
        }
    }

    class LinphoneRegistrationTracer: CoreDelegate {
        override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String?) {
            print("New registration state \(cstate) for user id \( String(describing: cfg.identityAddress?.asString()))\n")
        }
    }
    
    func registrationExample()
    {
        let factory = Factory.Instance
        do {
           // main loop for receiving notifications and doing background linphonecore work:
            mCore.autoIterateEnabled = true;
           
            mCore.addDelegate(delegate: mRegistrationTrace) // Add registration specific logs
            try mCore.start()
           
            proxy_cfg = try mCore.createProxyConfig() // create proxy config
            let from = try factory.createAddress(addr: "sip:peche5@sip.linphone.org")// parse identity
            // create authentication structure from identity
            let info = try factory.createAuthInfo(username: from.username, userid: "", passwd: "peche5", ha1: "", realm: "", domain: "")
            mCore.addAuthInfo(info: info) // add authentication info to LinphoneCore
           
            // configure proxy entries
            try proxy_cfg.setIdentityaddress(newValue: from) // set identity with user name and domain
            let server_addr = from.domain // extract domain address from identity
            try proxy_cfg.setServeraddr(newValue: server_addr) // we assume domain = proxy server address
            
            proxy_cfg.registerEnabled = true // activate registration for this proxy config
           
            try mCore.addProxyConfig(config: proxy_cfg!) // add proxy config to linphone core
            mCore.defaultProxyConfig = proxy_cfg // set to default proxy
        } catch {
            print(error)
        }
        
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let factory = Factory.Instance
        try? mCore = factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        
        if (DEBUG_LOGS)
        {
            // enable liblinphone logs.
            log = LoggingService.Instance
            logManager = LinphoneLoggingServiceManager()
            log!.addDelegate(delegate: logManager!)
            log!.logLevel = LogLevel.Debug
            Factory.Instance.enableLogCollection(state: LogCollectionState.Enabled)
        }
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(coreVersion: Core.getVersion)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        registrationExample();
    }

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}


}


struct SceneDelegate_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
