import AppKit
import ApplicationServices
import Foundation
import KarabinerElementsUserCommandReceiver

@main
enum CustomKarabinerWindowLayoutServer {
  // The receiver internally captures itself weakly, so the process must retain it.
  @MainActor private static var receiver: KEUserCommandReceiver?

  @MainActor
  static func main() {
    let application = NSApplication.shared
    let accessibilityOptions = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(accessibilityOptions)
    CommandCoordinator.start()

    Task {
      await startReceiver()
    }
    application.run()
  }

  @MainActor
  private static func startReceiver() async {
    let socketPath = KEUserCommandReceiver.defaultSocketPath()
    let instance = KEUserCommandReceiver(
      path: socketPath,
      onJSON: { json in
        do {
          let command = try UserCommand.decode(json: json)
          DispatchQueue.main.async {
            MainActor.assumeIsolated {
              CommandCoordinator.submit(command)
            }
          }
        } catch {
          fputs(
            "custom-karabiner-windowlayout-server ignored an invalid command: \(error)\n",
            stderr)
        }
      },
      onError: { error in
        fputs("custom-karabiner-windowlayout-server receiver error: \(error)\n", stderr)
      })

    do {
      try await instance.start()
      receiver = instance
      fputs(
        "custom-karabiner-windowlayout-server listening at \(socketPath)\n",
        stderr)
    } catch {
      fputs(
        "custom-karabiner-windowlayout-server failed to start: \(error)\n",
        stderr)
      exit(1)
    }
  }
}
