import Foundation

protocol WindowCycleToken: Equatable {
  var bundleIdentifier: String { get }
}

struct CycleTracker<Token: WindowCycleToken> {
  private struct State {
    let commandIdentifier: String
    let window: Token
    let index: Int
  }

  private var state: State?
  var cyclePolicy: CyclePolicy = .default

  mutating func nextIndex(
    commandIdentifier: String,
    window: Token,
    stepCount: Int,
    reset: Bool = false
  ) -> Int {
    precondition(stepCount > 0)

    let index: Int
    if !reset,
      let state,
      state.commandIdentifier == commandIdentifier,
      state.window == window
    {
      index = (state.index + 1) % stepCount
    } else {
      index = 0
    }

    state = State(commandIdentifier: commandIdentifier, window: window, index: index)
    return index
  }

  mutating func applicationDidActivate(bundleIdentifier: String?) {
    guard cyclePolicy.resetOnApplicationChange, let state else { return }
    if state.window.bundleIdentifier != bundleIdentifier {
      self.state = nil
    }
  }

  mutating func focusedWindowDidChange() {
    guard cyclePolicy.resetOnFocusedWindowChange else { return }
    state = nil
  }
}
