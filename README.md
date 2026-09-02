# karabiner-kt

You can read about this in [this blog post](https://kau.sh/blog/karabiner-kt).

> **Archived:** the TypeScript port [karabiner-ts](https://github.com/kaushikgopal/karabiner-ts) is
> now the canonical repo — both generators produce byte-identical `karabiner.json` (verified with
> `make parity`, sibling expected at `../karabiner-ts`), and new changes land in TypeScript only.
> This repository remains as a Kotlin reference.

### Prerequisites

* [Karabiner-Elements](https://karabiner-elements.pqrs.org/) installed.
* [Gradle](https://gradle.org/) for building the Kotlin project.

## Installation

The [repo is open source](https://github.com/kaushikgopal/karabiner-kt), so feel free to take a look
and customize.

Getting started is easy. Here's how to set it up from scratch:

```shell
# install karabiner-elements
brew install --cask karabiner-elements

# app uses a simple gradle app
brew install gradle

# let's clean up the karabiner folder if they existed
rm -rf ~/.config/karabiner
mkdir -p ~/.config/karabiner

# clone the repo
git clone https://github.com/kaushikgopal/karabiner-kt.git ~/.config/karabiner/karabiner-kt

# install the window server once
cd ~/.config/karabiner/karabiner-kt
make install-window-server
```

## Run the configurator

Now every time you want to run the configurator:

```shell
cd ~/.config/karabiner/karabiner-kt
make

# you might have to do this once a while (if you restart your mac etc.)
make restart-karabiner
```

The default `make` command only regenerates and installs `karabiner.json`; it does not rebuild,
replace, re-sign, or restart the window server. This keeps its macOS Accessibility identity stable.
Run `make install-window-server` explicitly only when the Swift server itself changes. Because the
server is ad-hoc signed, replacing its executable may require granting Accessibility permission to
the new build once.

This repository represents a personal setup and an approach to managing Karabiner configurations.
Feel free to adapt it to your needs! Create a [github issue](https://github.com/kaushikgopal/karabiner-kt/issues) if you run into problems.

## Responsive window shortcuts

Karabiner's low-latency `send_user_command` API sends window commands to the persistent Swift `custom-karabiner-windowlayout-server`.

- Hyper+M/W/O/S/B opens the configured app. Repeated presses alternate between tall and wide
  layouts, with app-specific horizontal/vertical offsets that keep overlapping windows clickable.
- Hyper+1 places 1Password at the bottom-right; Hyper+0 places Spotify at full height on the left.
- Hyper+T alternates Ghostty between centered tall and wide layouts without an offset.
- Hyper+Up/Down alternates the frontmost window between the corresponding half and two-thirds.
- Hyper+Left/Right cycles the frontmost window through the corresponding half, third, and two-thirds.
- Hyper+F cycles the frontmost window through maximized (fills the visible frame, not macOS
  fullscreen), a centered 90%×90% layout, and the frame it had when the cycle started.
- Changing the focused app or window resets the next command to its first layout.

The Swift process is a stable, app-agnostic executor. Version 3 commands carry the behavior policy
from Kotlin: application or frontmost target, screen selection, window scope and filtering, bounds,
insets, size constraints, resize anchors, cascade offsets, cycle/reset behavior, post-layout focus,
timeouts, and every frame in the layout cycle. Changing these policies only updates
`karabiner.json`.

`make install-window-server` builds and installs the server as
`~/Applications/custom-karabiner-windowlayout-server.app` and registers its LaunchAgent. Regular
layout configuration is carried in Karabiner's user-command payload, so changing it only requires
the default `make` command.

The server app needs a grant in **System Settings → Privacy & Security → Accessibility** because macOS protects control of other applications' windows. Its current ad-hoc signature may require granting access again after a server rebuild. It does not need Automation or Screen Recording permission.
