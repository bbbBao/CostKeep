//
//  CostKeepApp.swift
//  CostKeep
//
//  Created by Tianyi Bao on 12/29/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct CostKeepApp: App {
    init() {
        FirebaseApp.configure()
        if #available(iOS 14.0, *) {
            AppCheck.setAppCheckProviderFactory(DeviceCheckProvider())
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
