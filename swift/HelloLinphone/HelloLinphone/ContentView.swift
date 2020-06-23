//
//  ContentView.swift
//  HelloLinphone
//
//  Created by Danmei Chen on 23/06/2020.
//  Copyright © 2020 belledonne. All rights reserved.
//

import SwiftUI

struct ContentView: View {
	var coreVersion: String = ""
    var body: some View {
        Text("Hello, Linphone, Core Version is \(coreVersion)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
