package sh.kau.karabiner

import java.io.File
import kotlinx.serialization.json.Json
import sh.kau.karabiner.DeviceIdentifier.Companion.KINESIS
import sh.kau.karabiner.ModifierKeyCode.RightCommand

fun main() {

  val mainRules = createMainRules()

  val defaultProfile =
      Profile(
          name = "Default",
          selected = true,
          // fnFunctionKeys = functionKeys(),
          complexModifications = ComplexModifications(rules = mainRules),
          virtualHidKeyboard = VirtualHidKeyboard(countryCode = 0, keyboardType = "ansi"),
          devices = deviceSpecificConfigs(),
          parameters =
              Parameters(
                  simultaneousThresholdMilliseconds = 250,
                  toDelayedActionDelayMilliseconds = 10,
                  toIfAloneTimeoutMilliseconds = 250,
                  toIfHeldDownThresholdMilliseconds = 500,
              ),
      )

  val jsonEncoder = Json {
    prettyPrint = true
    encodeDefaults = true
    explicitNulls = false // Don't serialize null values
  }

  val karabinerJson =
      jsonEncoder.encodeToString(
          KarabinerConfig(
              global = GlobalSettings(showInMenuBar = false),
              profiles = listOf(defaultProfile),
          ),
      )

  try {
    val outputFile = File("karabiner.json")
    outputFile.writeText(karabinerJson)
    println("Successfully wrote karabiner.json to ${outputFile.absolutePath}")
  } catch (e: Exception) {
    System.err.println("Error writing karabiner.json: ${e.message}")
    e.printStackTrace()
  }
}

private fun deviceSpecificConfigs(): List<DeviceConfiguration> {

  return listOf(
      DeviceConfiguration(
          identifiers =
              DeviceIdentifier(
                  isKeyboard = true,
                  isPointingDevice = true,
                  productId = 45919,
                  vendorId = 1133,
              ),
          ignore = false,
          manipulateCapsLockLed = false,
      ),
      DeviceConfiguration(
          identifiers = DeviceIdentifier(isPointingDevice = true),
          simpleModifications =
              listOf(
                  SimpleModification(
                      from =
                          SimpleModificationKey(
                              keyCode = RightCommand,
                          ),
                      to =
                          listOf(
                              SimpleModificationValue(
                                  keyCode = ModifierKeyCode.RightControl,
                              )
                          ),
                  )
              ),
      ),
      DeviceConfiguration(
          identifiers = DeviceIdentifier(isKeyboard = true, productId = 50475, vendorId = 1133),
          ignore = true,
      ),
    // Kinesis mWave keyboard - enabled by default
    DeviceConfiguration(
        identifiers =
            DeviceIdentifier(
                isKeyboard = true,
                isPointingDevice = true,
                productId = 4097,
                vendorId = 10730,
            ),
        ignore = false,
        ignoreVendorEvents = true,
    ),
  )
}

// Create fn function keys
internal fun functionKeys(): List<FnFunctionKey> =
    listOf(
        FnFunctionKey(
            from = FromFnKey(KeyCode.F3),
            to = listOf(To(keyCode = KeyCode.MissionControl)),
        ),
        FnFunctionKey(from = FromFnKey(KeyCode.F4), to = listOf(To(keyCode = KeyCode.Launchpad))),
        FnFunctionKey(
            from = FromFnKey(KeyCode.F5),
            to = listOf(To(keyCode = KeyCode.IlluminationDecrement)),
        ),
        FnFunctionKey(
            from = FromFnKey(KeyCode.F6),
            to = listOf(To(keyCode = KeyCode.IlluminationIncrement)),
        ),
        FnFunctionKey(
            from = FromFnKey(KeyCode.F9),
            to = listOf(To(consumerKeyCode = "fastforward")),
        ),
    )
