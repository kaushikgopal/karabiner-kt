// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "CustomKarabinerWindowLayoutServer",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(
      url: "https://github.com/pqrs-org/Karabiner-Elements-user-command-receiver.git",
      exact: "1.2.0")
  ],
  targets: [
    .executableTarget(
      name: "CustomKarabinerWindowLayoutServer",
      dependencies: [
        .product(
          name: "KarabinerElementsUserCommandReceiver",
          package: "Karabiner-Elements-user-command-receiver")
      ]),
    .testTarget(
      name: "CustomKarabinerWindowLayoutServerTests",
      dependencies: ["CustomKarabinerWindowLayoutServer"]),
  ])
