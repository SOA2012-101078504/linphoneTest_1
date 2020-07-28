//
//  ContentView.swift
//  HelloLinphone
//
//  Created by Danmei Chen on 23/06/2020.
//  Copyright © 2020 belledonne. All rights reserved.
//

import linphonesw
import SwiftUI


class LinphoneCoreHolder : ObservableObject
{
    var mCore: Core!
    var proxy_cfg: ProxyConfig!
    var call: Call!
    let mRegistrationTracer = LinphoneRegistrationTracer()
    let mPhoneStateTracer = LinconePhoneStateTracer()
    
    var log : LoggingService?
    var logManager : LinphoneLoggingServiceManager?
    
    @Published var coreVersion: String = Core.getVersion
    @Published var callRunning : Bool = false;
    @Published var id : String = "sip:peche5@sip.linphone.org"
    @Published var passwd : String = "peche5"
    @Published var dest : String = "sip:arguillq@sip.linphone.org"
    
    
    @Published var logsEnabled : Bool = true;
    
    init()
    {
        
        let factory = Factory.Instance // Instanciate
        
        
        // set logsEnabled to false to disable logs collection
        if (logsEnabled)
        {
            log = LoggingService.Instance
            logManager = LinphoneLoggingServiceManager()
            log!.addDelegate(delegate: logManager!)
            log!.logLevel = LogLevel.Debug
            factory.enableLogCollection(state: LogCollectionState.Enabled)
        }
        
        // Initialize Linphone Core
        try? mCore = factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        // main loop for receiving notifications and doing background linphonecore work:
        mCore.autoIterateEnabled = true;
        try? mCore.start()
    }
    
    func registrationExample()
    {
        let factory = Factory.Instance
        do {
            mCore.addDelegate(delegate: mRegistrationTracer) // Add registration specific logs
           
            proxy_cfg = try mCore.createProxyConfig() // create proxy config
            let from = try factory.createAddress(addr: id)// parse identity
            // create authentication structure from identity
            let info = try factory.createAuthInfo(username: from.username, userid: "", passwd: passwd, ha1: "", realm: "", domain: "")
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
    
    
    // Initiate a call
    func startOutgoingCallExample()
    {
        if (!callRunning)
        {
            mCore.addDelegate(delegate: mPhoneStateTracer)
            
            // Place an outgoing call
            call = mCore.invite(url: dest)
            
            if (call == nil) {
                print("Could not place call to \(dest)\n")
            } else {
                print("Call to  \(dest) is in progress...")
                callRunning = true
            }
        }
                
    }
    
    // Terminate a call
    func stopOutgoingCallExample()
    {
        if (callRunning)
        {
            if (call.state != Call.State.End){
                // terminate the call
                print("Terminating the call...\n")
                do {
                    try call.terminate()
                    callRunning = false
                } catch {
                    print(error)
                }
             }
            mCore.removeDelegate(delegate: self.mPhoneStateTracer)
        }
    }
    
}



struct ContentView: View {
    
    @ObservedObject var coreHolder = LinphoneCoreHolder()
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Identity :")
                    .font(.headline)
                TextField("", text : $coreHolder.id)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Password :")
                    .font(.headline)
                TextField("", text : $coreHolder.passwd)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Button(action:  self.coreHolder.registrationExample)
            {
                Text("Login")
                    .font(.largeTitle)
                    .foregroundColor(Color.white)
                    .frame(width: 100.0, height: 50.0)
                    .background(Color.gray)
            }
            Spacer()
            HStack {
                Text("Call destination :")
                    .font(.headline)
                TextField("", text : $coreHolder.dest)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Button(action: self.coreHolder.startOutgoingCallExample)
                {
                    Text("Call")
                        .font(.largeTitle)
                        .foregroundColor(Color.white)
                        .frame(width: 130.0, height: 50.0)
                        .background(Color.green)
                }
                Spacer()
                Button(action: coreHolder.stopOutgoingCallExample) {
                    Text("Stop Call")
                        .font(.largeTitle)
                        .foregroundColor(Color.white)
                        .frame(width: 170.0, height: 50.0)
                        .background(Color.red)
                }
            }
            Text(coreHolder.callRunning ? "Call currently running" : "")
                .padding(.top, 5.0)
            Spacer()
            Text("Hello, Linphone, Core Version is")
            Text("\(coreHolder.coreVersion)")
        }
        .padding()
    }
}

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

class LinconePhoneStateTracer: CoreDelegate {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
