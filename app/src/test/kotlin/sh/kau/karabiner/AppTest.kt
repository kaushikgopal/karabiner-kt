package sh.kau.karabiner

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import sh.kau.karabiner.ModifierKeyCode.RightCommand
import sh.kau.karabiner.ModifierKeyCode.RightControl
import sh.kau.karabiner.ModifierKeyCode.RightOption
import sh.kau.karabiner.ModifierKeyCode.RightShift

class AppTest {

  @Test
  fun hyperAppLaunchersSendLowLatencyWindowLayoutCommands() {
    val rule =
        createMainRules().single {
          it.description == "Hyper app launchers with responsive window layouts"
        }
    val launchers = assertNotNull(rule.manipulators)
    val hyperModifiers = listOf(RightControl, RightCommand, RightOption, RightShift)
    val commands = launchers.map { assertNotNull(it.to?.single()?.sendUserCommand) }

    assertEquals(listOf(KeyCode.B, KeyCode.T), launchers.map { it.from.keyCode })
    assertEquals(
        listOf(hyperModifiers, hyperModifiers),
        launchers.map { it.from.modifiers?.mandatory },
    )
    assertEquals(listOf(1, 1), commands.map { it.payload["version"]?.jsonPrimitive?.int })
    assertEquals(
        listOf("open_and_layout", "open_and_layout"),
        commands.map { it.payload["command"]?.jsonPrimitive?.content },
    )
    assertEquals(
        listOf("net.imput.helium", "com.mitchellh.ghostty"),
        commands.map { it.payload["bundle_identifier"]?.jsonPrimitive?.content },
    )
    assertEquals(
        listOf(1050, 1200),
        commands.map { it.payload["width"]?.jsonObject?.get("min")?.jsonPrimitive?.int },
    )
    assertEquals(
        listOf(0.923, 0.845),
        commands.map {
          it.payload["height"]?.jsonObject?.get("compact_ratio")?.jsonPrimitive?.double
        },
    )
  }
}
