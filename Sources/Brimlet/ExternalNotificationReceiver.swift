import AppKit
import BrimletIPC

@MainActor final class ExternalNotificationReceiver {
    private let server = LocalNotificationServer()
    private let model: AppModel
    init(model: AppModel) { self.model = model }

    func start() {
        do {
            try server.start(requirements: { [weak self] in
                DispatchQueue.main.sync { self?.model.preferences.externalNotificationRequirements ?? [:] }
            }, receive: { [weak self] value, deadline in
                return DispatchQueue.main.sync {
                    guard Date() < deadline, let self else { return .unavailable }
                    return self.model.showExternalNotification(value)
                }
            })
        } catch {
            model.externalReceiverError = String(localized: "Notifications from other apps couldn’t be started. Try reopening Brimlet.")
        }
    }
}
