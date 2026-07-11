# karabiner-kt

You can read about this in [this blog post](https://kau.sh/blog/karabiner-kt).

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
```

## Run the configurator

Now every time you want to run the configurator:

```shell
cd ~/.config/karabiner/karabiner-kt
make

# you might have to do this once a while (if you restart your mac etc.)
make restart-karabiner
```

This repository represents a personal setup and an approach to managing Karabiner configurations.
Feel free to adapt it to your needs! Create a [github issue](https://github.com/kaushikgopal/karabiner-kt/issues) if you run into problems.

## Responsive app window shortcuts

Hyper+B and Hyper+T use Karabiner's low-latency `send_user_command` API to send window-layout commands to the persistent Swift `custom-karabiner-windowlayout-server`. The server launches Helium or Ghostty, sizes windows responsively for the display under the pointer, and cascades same-app windows.

`make` builds and installs the server as `~/.local/libexec/custom-karabiner-windowlayout-server`, registers its LaunchAgent, and updates `~/.config/karabiner/karabiner.json`.

The server needs a one-time grant in **System Settings → Privacy & Security → Accessibility** because macOS protects control of other applications' windows. It does not need Automation or Screen Recording permission.