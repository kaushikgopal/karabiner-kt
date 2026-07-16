import AppKit
import ApplicationServices
import Foundation
import KarabinerElementsUserCommandReceiver

@main
enum CustomKarabinerWindowLayoutServer {
  @MainActor
  static func main() {
    let application = NSApplication.shared
    let accessibilityOptions = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(accessibilityOptions)
    CommandCoordinator.start()

    Task.detached {
      await receiveCommands()
    }
    application.run()
  }

  private static func receiveCommands() async {
    let receiver = KEUserCommandReceiver(
      path: KEUserCommandReceiver.defaultSocketPath(),
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
            "custom-karabiner-windowlayout-server ignored an invalid command: \(error)\n", stderr)
        }
      },
      onError: { error in
        fputs("custom-karabiner-windowlayout-server receiver error: \(error)\n", stderr)
      })

    do {
      try await receiver.start()
      print(
        "custom-karabiner-windowlayout-server listening at \(KEUserCommandReceiver.defaultSocketPath())"
      )
      while true {
        try await Task.sleep(for: .seconds(3600))
      }
    } catch {
      fputs("custom-karabiner-windowlayout-server failed to start: \(error)\n", stderr)
      exit(1)
    }
  }
}
