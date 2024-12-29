import Foundation
import FirebaseCore
import FirebaseAppCheck

class AppCheckDebugHelper {
    static func getDebugToken() {
        #if DEBUG
        let appCheck = AppCheck.appCheck()
        appCheck.token(forcingRefresh: false) { token, error in
            if let error = error {
                print("Error getting debug token: \(error)")
                return
            }
            if let token = token {
                print("✅ App Check Debug Token: \(token.token)")
            }
        }
        #endif
    }
} 