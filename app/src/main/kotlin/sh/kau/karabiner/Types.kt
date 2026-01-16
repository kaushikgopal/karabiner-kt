package sh.kau.karabiner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

@Serializable
data class KarabinerRule(
    val description: String? = null,
    val manipulators: List<Manipulator>? = null
)

@Serializable
data class Manipulator(
    val type: String = "basic", // Typically "basic"
    val from: From,
    @SerialName("to") val to: List<To>? = null,
    @SerialName("to_if_alone") val toIfAlone: List<To>? = null,
    @SerialName("to_after_key_up") val toAfterKeyUp: List<To>? = null,
    @SerialName("to_if_held_down") // This was missing in TS types but present in JSON
    val toIfHeldDown: List<To>? = null,
    val parameters: Parameters? = null,
    val conditions: List<Condition>? = null,
    val description: String? = null
)

@Serializable
data class From(
    @Serializable(with = KeyCodeAsStringSerializer::class)
    @SerialName("key_code") val keyCode: KeyCode? = null,
    val modifiers: FromModifiers? = null,
    @Serializable(with = SimultaneousKeyCodeListSerializer::class)
    val simultaneous: List<KeyCode>? = null,
    @SerialName("simultaneous_options") val simultaneousOptions: SimultaneousOptions? = null,
) {
  companion object {
    fun with(
        fromKeyCode: KeyCode,
        modifiers: FromModifiers? = null,
    ) =
        From(
            keyCode = fromKeyCode,
            modifiers = modifiers ?: FromModifiers(optional = listOf(ModifierKeyCode.Any)),
        )
  }
}

@Serializable
data class FromModifiers(
    @Serializable(with = ModifierKeyCodeListSerializer::class)
    val optional: List<ModifierKeyCode>? = null,
    @Serializable(with = ModifierKeyCodeListSerializer::class)
    val mandatory: List<ModifierKeyCode>? = null
)

@Serializable
data class To(
    @Serializable(with = KeyCodeAsStringSerializer::class)
    @SerialName("key_code") val keyCode: KeyCode? = null,
    @Serializable(with = ModifierKeyCodeListSerializer::class)
    val modifiers: List<ModifierKeyCode?>? = null,
    @SerialName("consumer_key_code") val consumerKeyCode: String? = null,
    @SerialName("shell_command") val shellCommand: String? = null,
    @SerialName("set_variable") val setVariable: SetVariable? = null,
    @SerialName("mouse_key") val mouseKey: MouseKey? = null,
    @SerialName("pointing_button") val pointingButton: String? = null,
    @SerialName("software_function") val softwareFunction: SoftwareFunction? = null
    // `hold_down_milliseconds` is sometimes seen with `to` events. Add if needed.
) {
  companion object {
    fun with(
        toKey: KeyCode? = null,
        toKeyModifiers: List<ModifierKeyCode?>? = null,
        cmd: ShellCmd? = null,
        mouseKey: MouseKey? = null,
        pointingButton: String? = null,
    ): List<To> {

      val list = mutableListOf<To>()

      if (arrayOf(cmd, toKey, mouseKey, pointingButton).count { it != null } == 2)
          throw IllegalArgumentException("Cannot have two of these instructions set simultaneously")

      if (cmd != null) return list.apply { add(To(shellCommand = cmd)) }
      if (toKey != null) return list.apply { add(To(keyCode = toKey, modifiers = toKeyModifiers)) }
      if (mouseKey != null) return list.apply { add(To(mouseKey = mouseKey)) }
      if (pointingButton != null) return list.apply { add(To(pointingButton = pointingButton)) }

      throw IllegalStateException("Could not build To instruction")
    }
  }
}

enum class ToType {
  NORMAL,
  IF_ALONE,
  AFTER_KEY_UP,
  IF_HELD_DOWN
}

@Serializable
data class Parameters(
    @SerialName("basic.simultaneous_threshold_milliseconds")
    val simultaneousThresholdMilliseconds: Long? = null,
    @SerialName("basic.to_delayed_action_delay_milliseconds")
    val toDelayedActionDelayMilliseconds: Long? = null,
    @SerialName("basic.to_if_alone_timeout_milliseconds")
    val toIfAloneTimeoutMilliseconds: Long? = null,
    @SerialName("basic.to_if_held_down_threshold_milliseconds")
    val toIfHeldDownThresholdMilliseconds: Long? = null,
    // Potentially add other parameters if they exist, or allow for a map
    // For now, sticking to explicitly defined ones
)

@Serializable
data class SimultaneousOptions(
    @SerialName("key_down_order")
    val keyDownOrder: String? = null, // Consider enum: "insensitive", "strict", "strict_inverse"
    @SerialName("detect_key_down_uninterruptedly")
    val detectKeyDownUninterruptedly: Boolean? = null,
    @SerialName("key_up_order")
    val keyUpOrder: String? = null, // Consider enum: "insensitive", "strict", "strict_inverse"
    @SerialName("key_up_when") val keyUpWhen: String? = null, // Consider enum: "any", "all"
    @SerialName("to_after_key_up") val toAfterKeyUp: List<To>? = null
)

@Serializable data class SetVariable(val name: String, val value: JsonPrimitive)

@Serializable
data class MouseKey(
    val x: Int? = null,
    val y: Int? = null,
    @SerialName("speed_multiplier") val speedMultiplier: Double? = null,
    @SerialName("vertical_wheel") val verticalWheel: Int? = null,
    @SerialName("horizontal_wheel") val horizontalWheel: Int? = null
)

@Serializable
data class SoftwareFunction(
    @SerialName("iokit_power_management_sleep_system")
    val iokitPowerManagementSleepSystem: JsonObject? = null // Representing an empty object {}
)

@Serializable(with = KeyCodeAsStringSerializer::class)
sealed class KeyCode {
  @Serializable @SerialName("caps_lock") object CapsLock : KeyCode()

  @Serializable @SerialName("return_or_enter") object ReturnOrEnter : KeyCode()

  @Serializable @SerialName("escape") object Escape : KeyCode()

  @Serializable @SerialName("delete_or_backspace") object DeleteOrBackspace : KeyCode()

  @Serializable @SerialName("delete_forward") object DeleteForward : KeyCode()

  @Serializable @SerialName("tab") object Tab : KeyCode()

  @Serializable @SerialName("spacebar") object Spacebar : KeyCode()

  @Serializable @SerialName("hyphen") object Hyphen : KeyCode()

  @Serializable @SerialName("equal_sign") object EqualSign : KeyCode()

  @Serializable @SerialName("open_bracket") object OpenBracket : KeyCode()

  @Serializable @SerialName("close_bracket") object CloseBracket : KeyCode()

  @Serializable @SerialName("backslash") object Backslash : KeyCode()

  @Serializable @SerialName("non_us_pound") object NonUsPound : KeyCode()

  @Serializable @SerialName("semicolon") object Semicolon : KeyCode()

  @Serializable @SerialName("quote") object Quote : KeyCode()

  @Serializable @SerialName("grave_accent_and_tilde") object GraveAccentAndTilde : KeyCode()

  @Serializable @SerialName("comma") object Comma : KeyCode()

  @Serializable @SerialName("period") object Period : KeyCode()

  @Serializable @SerialName("slash") object Slash : KeyCode()

  @Serializable @SerialName("non_us_backslash") object NonUsBackslash : KeyCode()

  @Serializable @SerialName("up_arrow") object UpArrow : KeyCode()

  @Serializable @SerialName("down_arrow") object DownArrow : KeyCode()

  @Serializable @SerialName("left_arrow") object LeftArrow : KeyCode()

  @Serializable @SerialName("right_arrow") object RightArrow : KeyCode()

  @Serializable @SerialName("page_up") object PageUp : KeyCode()

  @Serializable @SerialName("page_down") object PageDown : KeyCode()

  @Serializable @SerialName("home") object Home : KeyCode()

  @Serializable @SerialName("end") object End : KeyCode()

  @Serializable @SerialName("a") object A : KeyCode()

  @Serializable @SerialName("b") object B : KeyCode()

  @Serializable @SerialName("c") object C : KeyCode()

  @Serializable @SerialName("d") object D : KeyCode()

  @Serializable @SerialName("e") object E : KeyCode()

  @Serializable @SerialName("f") object F : KeyCode()

  @Serializable @SerialName("g") object G : KeyCode()

  @Serializable @SerialName("h") object H : KeyCode()

  @Serializable @SerialName("i") object I : KeyCode()

  @Serializable @SerialName("j") object J : KeyCode()

  @Serializable @SerialName("k") object K : KeyCode()

  @Serializable @SerialName("l") object L : KeyCode()

  @Serializable @SerialName("m") object M : KeyCode()

  @Serializable @SerialName("n") object N : KeyCode()

  @Serializable @SerialName("o") object O : KeyCode()

  @Serializable @SerialName("p") object P : KeyCode()

  @Serializable @SerialName("q") object Q : KeyCode()

  @Serializable @SerialName("r") object R : KeyCode()

  @Serializable @SerialName("s") object S : KeyCode()

  @Serializable @SerialName("t") object T : KeyCode()

  @Serializable @SerialName("u") object U : KeyCode()

  @Serializable @SerialName("v") object V : KeyCode()

  @Serializable @SerialName("w") object W : KeyCode()

  @Serializable @SerialName("x") object X : KeyCode()

  @Serializable @SerialName("y") object Y : KeyCode()

  @Serializable @SerialName("z") object Z : KeyCode()

  @Serializable @SerialName("1") object Num1 : KeyCode()

  @Serializable @SerialName("2") object Num2 : KeyCode()

  @Serializable @SerialName("3") object Num3 : KeyCode()

  @Serializable @SerialName("4") object Num4 : KeyCode()

  @Serializable @SerialName("5") object Num5 : KeyCode()

  @Serializable @SerialName("6") object Num6 : KeyCode()

  @Serializable @SerialName("7") object Num7 : KeyCode()

  @Serializable @SerialName("8") object Num8 : KeyCode()

  @Serializable @SerialName("9") object Num9 : KeyCode()

  @Serializable @SerialName("0") object Num0 : KeyCode()

  @Serializable @SerialName("f1") object F1 : KeyCode()

  @Serializable @SerialName("f2") object F2 : KeyCode()

  @Serializable @SerialName("f3") object F3 : KeyCode()

  @Serializable @SerialName("f4") object F4 : KeyCode()

  @Serializable @SerialName("f5") object F5 : KeyCode()

  @Serializable @SerialName("f6") object F6 : KeyCode()

  @Serializable @SerialName("f7") object F7 : KeyCode()

  @Serializable @SerialName("f8") object F8 : KeyCode()

  @Serializable @SerialName("f9") object F9 : KeyCode()

  @Serializable @SerialName("f10") object F10 : KeyCode()

  @Serializable @SerialName("f11") object F11 : KeyCode()

  @Serializable @SerialName("f12") object F12 : KeyCode()

  @Serializable @SerialName("f13") object F13 : KeyCode()

  @Serializable @SerialName("f14") object F14 : KeyCode()

  @Serializable @SerialName("f15") object F15 : KeyCode()

  @Serializable @SerialName("f16") object F16 : KeyCode()

  @Serializable @SerialName("f17") object F17 : KeyCode()

  @Serializable @SerialName("f18") object F18 : KeyCode()

  @Serializable @SerialName("f19") object F19 : KeyCode()

  @Serializable @SerialName("f20") object F20 : KeyCode()

  @Serializable @SerialName("f21") object F21 : KeyCode()

  @Serializable @SerialName("f22") object F22 : KeyCode()

  @Serializable @SerialName("f23") object F23 : KeyCode()

  @Serializable @SerialName("f24") object F24 : KeyCode()

  @Serializable
  @SerialName("display_brightness_decrement")
  object DisplayBrightnessDecrement : KeyCode()

  @Serializable
  @SerialName("display_brightness_increment")
  object DisplayBrightnessIncrement : KeyCode()

  @Serializable @SerialName("mission_control") object MissionControl : KeyCode()

  @Serializable @SerialName("launchpad") object Launchpad : KeyCode()

  @Serializable @SerialName("dashboard") object Dashboard : KeyCode()

  @Serializable @SerialName("illumination_decrement") object IlluminationDecrement : KeyCode()

  @Serializable @SerialName("illumination_increment") object IlluminationIncrement : KeyCode()

  @Serializable @SerialName("rewind") object Rewind : KeyCode()

  @Serializable @SerialName("play_or_pause") object PlayOrPause : KeyCode()

  @Serializable @SerialName("fastforward") object Fastforward : KeyCode()

  @Serializable @SerialName("mute") object Mute : KeyCode()

  @Serializable @SerialName("volume_decrement") object VolumeDecrement : KeyCode()

  @Serializable @SerialName("volume_increment") object VolumeIncrement : KeyCode()

  @Serializable @SerialName("eject") object Eject : KeyCode()

  @Serializable
  @SerialName("apple_display_brightness_decrement")
  object AppleDisplayBrightnessDecrement : KeyCode()

  @Serializable
  @SerialName("apple_display_brightness_increment")
  object AppleDisplayBrightnessIncrement : KeyCode()

  @Serializable
  @SerialName("apple_top_case_display_brightness_decrement")
  object AppleTopCaseDisplayBrightnessDecrement : KeyCode()

  @Serializable
  @SerialName("apple_top_case_display_brightness_increment")
  object AppleTopCaseDisplayBrightnessIncrement : KeyCode()

  @Serializable @SerialName("keypad_num_lock") object KeypadNumLock : KeyCode()

  @Serializable @SerialName("keypad_slash") object KeypadSlash : KeyCode()

  @Serializable @SerialName("keypad_asterisk") object KeypadAsterisk : KeyCode()

  @Serializable @SerialName("keypad_hyphen") object KeypadHyphen : KeyCode()

  @Serializable @SerialName("keypad_plus") object KeypadPlus : KeyCode()

  @Serializable @SerialName("keypad_enter") object KeypadEnter : KeyCode()

  @Serializable @SerialName("keypad_1") object Keypad1 : KeyCode()

  @Serializable @SerialName("keypad_2") object Keypad2 : KeyCode()

  @Serializable @SerialName("keypad_3") object Keypad3 : KeyCode()

  @Serializable @SerialName("keypad_4") object Keypad4 : KeyCode()

  @Serializable @SerialName("keypad_5") object Keypad5 : KeyCode()

  @Serializable @SerialName("keypad_6") object Keypad6 : KeyCode()

  @Serializable @SerialName("keypad_7") object Keypad7 : KeyCode()

  @Serializable @SerialName("keypad_8") object Keypad8 : KeyCode()

  @Serializable @SerialName("keypad_9") object Keypad9 : KeyCode()

  @Serializable @SerialName("keypad_0") object Keypad0 : KeyCode()

  @Serializable @SerialName("keypad_period") object KeypadPeriod : KeyCode()

  @Serializable @SerialName("keypad_equal_sign") object KeypadEqualSign : KeyCode()

  @Serializable @SerialName("keypad_comma") object KeypadComma : KeyCode()

  @Serializable @SerialName("keypad_equal_sign_as400") object KeypadEqualSignAs400 : KeyCode()

  @Serializable @SerialName("locking_caps_lock") object LockingCapsLock : KeyCode()

  @Serializable @SerialName("locking_num_lock") object LockingNumLock : KeyCode()

  @Serializable @SerialName("locking_scroll_lock") object LockingScrollLock : KeyCode()

  @Serializable @SerialName("alternate_erase") object AlternateErase : KeyCode()

  @Serializable @SerialName("sys_req_or_attention") object SysReqOrAttention : KeyCode()

  @Serializable @SerialName("cancel") object Cancel : KeyCode()

  @Serializable @SerialName("clear") object Clear : KeyCode()

  @Serializable @SerialName("prior") object Prior : KeyCode()

  @Serializable @SerialName("return") object Return : KeyCode()

  @Serializable @SerialName("separator") object Separator : KeyCode()

  @Serializable @SerialName("out") object Out : KeyCode()

  @Serializable @SerialName("oper") object Oper : KeyCode()

  @Serializable @SerialName("clear_or_again") object ClearOrAgain : KeyCode()

  @Serializable @SerialName("cr_sel_or_props") object CrSelOrProps : KeyCode()

  @Serializable @SerialName("ex_sel") object ExSel : KeyCode()

  @Serializable
  @SerialName("vk_consumer_brightness_down")
  object VkConsumerBrightnessDown : KeyCode()

  @Serializable @SerialName("vk_consumer_brightness_up") object VkConsumerBrightnessUp : KeyCode()

  @Serializable @SerialName("vk_mission_control") object VkMissionControl : KeyCode()

  @Serializable @SerialName("vk_launchpad") object VkLaunchpad : KeyCode()

  @Serializable @SerialName("vk_dashboard") object VkDashboard : KeyCode()

  @Serializable
  @SerialName("vk_consumer_illumination_down")
  object VkConsumerIlluminationDown : KeyCode()

  @Serializable
  @SerialName("vk_consumer_illumination_up")
  object VkConsumerIlluminationUp : KeyCode()

  @Serializable @SerialName("vk_consumer_previous") object VkConsumerPrevious : KeyCode()

  @Serializable @SerialName("vk_consumer_play") object VkConsumerPlay : KeyCode()

  @Serializable @SerialName("vk_consumer_next") object VkConsumerNext : KeyCode()

  val name = this::class.simpleName ?: error("Unknown key name")

  companion object {
    fun from(name: String): KeyCode {
      return KeyCode::class
          .sealedSubclasses
          .firstNotNullOfOrNull { it.objectInstance }
          ?.takeIf { it::class.simpleName.equals(name, ignoreCase = true) }
          ?: error("Unknown KeyCode: $name")
    }
  }
}

@Serializable(with = ModifierKeyCodeAsStringSerializer::class)
sealed class ModifierKeyCode : KeyCode() {
  @Serializable @SerialName("hyper") object Hyper : KeyCode()

  @Serializable @SerialName("left_control") object LeftControl : ModifierKeyCode()

  @Serializable @SerialName("left_shift") object LeftShift : ModifierKeyCode()

  @Serializable @SerialName("left_option") object LeftOption : ModifierKeyCode()

  @Serializable @SerialName("left_command") object LeftCommand : ModifierKeyCode()

  @Serializable @SerialName("right_control") object RightControl : ModifierKeyCode()

  @Serializable @SerialName("right_shift") object RightShift : ModifierKeyCode()

  @Serializable @SerialName("right_option") object RightOption : ModifierKeyCode()

  @Serializable @SerialName("right_command") object RightCommand : ModifierKeyCode()

  @Serializable @SerialName("fn") object Fn : ModifierKeyCode()

  @Serializable @SerialName("command") object Command : ModifierKeyCode()

  @Serializable @SerialName("control") object Control : ModifierKeyCode()

  @Serializable @SerialName("option") object Option : ModifierKeyCode()

  @Serializable @SerialName("shift") object Shift : ModifierKeyCode()

  @Serializable @SerialName("left_alt") object LeftAlt : ModifierKeyCode()

  @Serializable @SerialName("left_gui") object LeftGui : ModifierKeyCode()

  @Serializable @SerialName("right_alt") object RightAlt : ModifierKeyCode()

  @Serializable @SerialName("right_gui") object RightGui : ModifierKeyCode()

  @Serializable @SerialName("any") object Any : ModifierKeyCode()
}

@Serializable
sealed interface Condition {

  @Serializable
  @SerialName("frontmost_application_if")
  data class FrontmostApplicationIfCondition(
      @SerialName("bundle_identifiers") var bundleIds: List<String>? = null,
      @SerialName("file_paths") var filePaths: List<String>? = null,
  ) : Condition

  @Serializable
  @SerialName("frontmost_application_unless")
  data class FrontmostApplicationUnlessCondition(
      @SerialName("bundle_identifiers") var bundleIds: List<String>? = null,
      @SerialName("file_paths") var filePaths: List<String>? = null,
  ) : Condition

  @Serializable
  @SerialName("device_if")
  data class DeviceIfCondition(
      var identifiers: List<DeviceIdentifier>? = null,
  ) : Condition

  @Serializable
  @SerialName("device_unless")
  data class DeviceUnlessCondition(
      var identifiers: List<DeviceIdentifier>? = null,
  ) : Condition

  @Serializable
  @SerialName("device_exists_if")
  data class DeviceExistsIfCondition(
      val identifiers: List<DeviceIdentifier>,
  ) : Condition

  @Serializable
  @SerialName("device_exists_unless")
  data class DeviceExistsUnlessCondition(
      val identifiers: List<DeviceIdentifier>,
  ) : Condition

  @Serializable
  @SerialName("keyboard_type_if")
  data class KeyboardTypeIfCondition(
      @SerialName("keyboard_types") val keyboardTypes: List<String>,
  ) : Condition

  @Serializable
  @SerialName("keyboard_type_unless")
  data class KeyboardTypeUnlessCondition(
      @SerialName("keyboard_types") val keyboardTypes: List<String>,
  ) : Condition

  @Serializable
  data class InputSourceSpec(
      val language: String? = null,
      @SerialName("input_source_id") val inputSourceId: String? = null,
      @SerialName("input_mode_id") val inputModeId: String? = null
  )

  @Serializable
  @SerialName("input_source_if")
  data class InputSourceIfCondition(
      @SerialName("input_sources") val inputSources: List<InputSourceSpec>,
  ) : Condition

  @Serializable
  @SerialName("input_source_unless")
  data class InputSourceUnlessCondition(
      @SerialName("input_sources") val inputSources: List<InputSourceSpec>,
  ) : Condition

  @Serializable
  @SerialName("variable_if")
  data class VariableIfCondition(
      val name: String,
      val value: JsonPrimitive,
  ) : Condition

  @Serializable
  @SerialName("variable_unless")
  data class VariableUnlessCondition(
      val name: String,
      val value: JsonPrimitive,
  ) : Condition

  @Serializable
  @SerialName("event_changed_if")
  data class EventChangedIfCondition(
      val value: Boolean,
  ) : Condition

  @Serializable
  @SerialName("event_changed_unless")
  data class EventChangedUnlessCondition(
      val value: Boolean,
  ) : Condition
}

@Serializable
data class DeviceConfiguration(
    @SerialName("device_id") val deviceId: Long? = null,
    val identifiers: DeviceIdentifier, // not the same as above
    @SerialName("is_apple") val isApple: Boolean? = null,
    @SerialName("is_built_in_pointing_device") val isBuiltInPointingDevice: Boolean? = null,
    @SerialName("manufacturer") val manufacturer: String? = null,
    @SerialName("product") val product: String? = null,
    @SerialName("transport") val transport: String? = null,
    //
    @SerialName("fn_function_keys") val fnFunctionKeys: List<FnFunctionKey>? = null,
    @SerialName("ignore") val ignore: Boolean? = null,
    @SerialName("ignore_vendor_events") val ignoreVendorEvents: Boolean? = null,
    @SerialName("manipulate_caps_lock_led") val manipulateCapsLockLed: Boolean? = null,
    @SerialName("simple_modifications") val simpleModifications: List<SimpleModification>? = null,
    @SerialName("treat_as_built_in_keyboard") val treatAsBuiltInKeyboard: Boolean? = null,
    @SerialName("disable_built_in_keyboard_if_exists")
    val disableBuiltInKeyboardIfExists: Boolean? = null,
) {
  companion object {
    //    val APPLE_BUILTIN_KEYBOARD =
    //        DeviceConfiguration(
    //            identifiers = DeviceIdentifier(isKeyboard = true),
    //            isApple = true,
    //            manufacturer = "Apple",
    //            product = "Apple Internal Keyboard / Trackpad",
    //            transport = "FIFO",
    //        )
    //    val APPLE_BUILTIN_TRACKPAD =
    //        DeviceConfiguration(
    //            identifiers = DeviceIdentifier(isPointingDevice = true),
    //            isApple = true,
    //            isBuiltInPointingDevice = true,
    //            manufacturer = "Apple",
    //            product = "Apple Internal Keyboard / Trackpad",
    //            transport = "FIFO",
    //        )
  }
}

@Serializable
data class DeviceIdentifier(
    // karabiner docs are not great here
    // https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/device/
    // confirmed the below to work from experience
    @SerialName("description") val Description: String? = null,
    @SerialName("vendor_id") val vendorId: Long? = null,
    @SerialName("product_id") val productId: Long? = null,
    @SerialName("is_built_in_keyboard") val isBuiltInKeyboard: Boolean? = null,
    @SerialName("is_keyboard") val isKeyboard: Boolean? = null,
    @SerialName("is_pointing_device") val isPointingDevice: Boolean? = null,
    @SerialName("is_touch_bar") val isTouchBar: Boolean? = null,
    // @SerialName("is_virtual_device") val isVirtualDevice: Boolean? = null,

    /** device_address will change when you replace the hardware */
    @SerialName("device_address") val deviceAddress: String? = null,

    /** location_id will change when you change USB port */
    @SerialName("location_id") val locationId: Long? = null,
) {
  companion object {

    val APPLE_KEYBOARDS =
        listOf(
            DeviceIdentifier(vendorId = 1452, isKeyboard = true),
            DeviceIdentifier(vendorId = 76, isKeyboard = true),
            DeviceIdentifier(isBuiltInKeyboard = true),
        )

    val ANNE_PRO_2 = DeviceIdentifier(vendorId = 1241L, productId = 41618L)
    val MS_SCULPT = DeviceIdentifier(vendorId = 1118L, productId = 1957L)
    val TADA68 = DeviceIdentifier(vendorId = 65261L, productId = 4611L)
    val KINESIS = DeviceIdentifier(vendorId = 10730L, isKeyboard = true)
    val LOGITECH_G915 = DeviceIdentifier(vendorId = 1133L)
    val KEYCHRON = DeviceIdentifier(vendorId = 76L)
  }
}

// Root structure for the final JSON (approximated from karabiner.json)
@Serializable
data class KarabinerConfig(
    val global: GlobalSettings? = null, // Made nullable to match some karabiner.json examples
    val profiles: List<Profile>
)

@Serializable
data class GlobalSettings(
    @SerialName("check_for_updates_on_startup") val checkForUpdatesOnStartup: Boolean? = null,
    @SerialName("show_in_menu_bar") val showInMenuBar: Boolean? = null,
    @SerialName("show_profile_name_in_menu_bar") val showProfileNameInMenuBar: Boolean? = null,
    @SerialName("unsafe_ui") val unsafeUi: Boolean? = null
    // Add other global settings as needed
)

@Serializable
data class Profile(
    val name: String,
    @SerialName("complex_modifications") val complexModifications: ComplexModifications,
    @SerialName("fn_function_keys") val fnFunctionKeys: List<FnFunctionKey>? = null,
    //    @SerialName("simple_modifications") val simpleModifications: List<SimpleModification>? =
    // null,
    val selected: Boolean? = null,
    @SerialName("virtual_hid_keyboard")
    val virtualHidKeyboard: VirtualHidKeyboard = VirtualHidKeyboard(),
    @SerialName("devices") val devices: List<DeviceConfiguration>? = null,
    @SerialName("parameters") val parameters: Parameters? = null,
)

@Serializable
data class ComplexModifications(
    val parameters: Parameters? = null, // Re-using Parameters from above
    val rules: List<KarabinerRule>
)

@Serializable
data class VirtualHidKeyboard(
    @SerialName("country_code") val countryCode: Int = 0,
    @SerialName("mouse_key_xy_scale") val mouseKeyXyScale: Double? = null,
    @SerialName("indicate_sticky_modifier_keys_state")
    val indicateStickyModifierKeysState: Boolean? = null,
    @SerialName("keyboard_type_v2") // Original TS used keyboard_type_v2, JSON uses keyboard_type
    val keyboardType: String = "ansi" // e.g., "ansi"
)

@Serializable data class FromFnKey(
    @Serializable(with = KeyCodeAsStringSerializer::class)
    @SerialName("key_code") val keyCode: KeyCode
)

@Serializable data class FnFunctionKey(val from: FromFnKey, val to: List<To>)

@Serializable
data class SimpleModification(
    val from: SimpleModificationKey,
    val to: List<SimpleModificationValue>
)

@Serializable data class SimpleModificationKey(
    @Serializable(with = KeyCodeAsStringSerializer::class)
    @SerialName("key_code") val keyCode: KeyCode
)

@Serializable data class SimpleModificationValue(
    @Serializable(with = KeyCodeAsStringSerializer::class)
    @SerialName("key_code") val keyCode: KeyCode
)