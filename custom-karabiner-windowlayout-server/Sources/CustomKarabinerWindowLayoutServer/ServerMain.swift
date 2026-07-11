import ApplicationServices
import Foundation
import KarabinerElementsUserCommandReceiver

@main
enum CustomKarabinerWindowLayoutServer {
  static func main() async {
    let accessibilityOptions = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(accessibilityOptions)

    let receiver = KEUserCommandReceiver(
      path: KEUserCommandReceiver.defaultSocketPath(),
      onJSON: { json in
        do {
          let command = try LayoutCommand.decode(json: json)
          Task { @MainActor in
            CommandCoordinator.submit(command)
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
