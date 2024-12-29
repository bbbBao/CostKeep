//
//  CostKeepApp.swift
//  CostKeep
//
//  Created by Tianyi Bao on 12/29/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("Debug - Configuring Firebase")
        
        
        // Configure and activate App Check
        Task {
            do {
                if #available(iOS 14.0, *) {
                    print("Debug - Setting up App Check with Device Check provider")
                    let provider = DeviceCheckProvider()
                    AppCheck.setAppCheckProviderFactory(provider)
                    
                    // Wait for App Check token
                    let appCheck = AppCheck.appCheck()
                    let token = try await appCheck.token(forcingRefresh: true)
                    print("✅ App Check Token received: \(token.token)")
                } else {
                    print("Debug - Setting up App Check with Debug provider")
                    #if DEBUG
                    let providerFactory = AppCheckDebugProviderFactory()
                    AppCheck.setAppCheckProviderFactory(providerFactory)
                    #endif
                }
            } catch {
                print("❌ Error activating App Check: \(error)")
            }
        }
        
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct CostKeepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
