import Foundation
import BrimletIPC

// Development-only, separate-process check. It never loads either app's settings.
@main struct IPCProbe {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 4 else { exit(2) }
        let requirement = try ApplicationIdentity.requirement(at: URL(fileURLWithPath: args[3]))
        if args[1] == "server" {
            let server = LocalNotificationServer(path: args[2])
            try server.start(requirements: { ["com.hamzabasaran.brimlet.ipc-probe": requirement] }, receive: { _, _ in .displayed })
            try await Task.sleep(for: .seconds(20))
            server.stop()
        } else {
            let result = await LocalNotificationChannel.send(
                ExternalNotification(sourceBundleID: "com.hamzabasaran.brimlet.ipc-probe", title: "IPC test", body: ""),
                receiverRequirement: requirement, path: args[2])
            print("Sandboxed client delivery: \(result.rawValue)")
            exit(result == .displayed ? 0 : 1)
        }
    }
}
