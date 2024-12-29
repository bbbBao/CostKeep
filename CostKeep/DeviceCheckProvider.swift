import FirebaseCore
import FirebaseAppCheck
import DeviceCheck

@available(iOS 14.0, *)
class DeviceCheckProvider: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
} 