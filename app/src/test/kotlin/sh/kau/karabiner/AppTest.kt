package sh.kau.karabiner

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import sh.kau.karabiner.ModifierKeyCode.RightCommand
import sh.kau.karabiner.ModifierKeyCode.RightControl
import sh.kau.karabiner.ModifierKeyCode.RightOption
import sh.kau.karabiner.ModifierKeyCode.RightShift

class AppTest {

  @Test
  fun hyperAppLaunchersSendCyclingLayoutCommands() {
    val launchers = manipulatorsFor("Hyper app launchers with cycling window layouts")
    val commands = launchers.map { assertNotNull(it.to?.single()?.sendUserCommand) }

    assertEquals(
        listOf(KeyCode.Num1, KeyCode.M, KeyCode.O, KeyCode.S, KeyCode.Num0, KeyCode.B, KeyCode.T),
        launchers.map { it.from.keyCode },
    )
    assertHyperModifiers(launchers)
    assertEquals(List(7) { 2 }, commands.map { it.payload["version"]?.jsonPrimitive?.int })
    assertEquals(
        List(7) { "cycle_application_layout" },
        commands.map { it.payload["command"]?.jsonPrimitive?.content },
    )
    assertEquals(
        listOf(
            "com.1password.1password",
            "com.apple.MobileSMS",
            "md.obsidian",
            "com.tinyspeck.slackmacgap",
            "com.spotify.client",
            "net.imput.helium",
            "com.mitchellh.ghostty",
        ),
        commands.map { it.payload["bundle_identifier"]?.jsonPrimitive?.content },
    )
    assertEquals(List(7) { 2 }, commands.map { it.payload["layouts"]?.jsonArray?.size })

    val layouts = commands.first().payload["layouts"]!!.jsonArray
    assertEquals(1050, layouts[0].jsonObject["width"]?.jsonObject?.get("min")?.jsonPrimitive?.int)
    assertEquals(
        0.923,
        layouts[0].jsonObject["height"]?.jsonObject?.get("compact_ratio")?.jsonPrimitive?.double,
    )
    assertEquals(1200, layouts[1].jsonObject["width"]?.jsonObject?.get("min")?.jsonPrimitive?.int)
    assertEquals(
        0.845,
        layouts[1].jsonObject["height"]?.jsonObject?.get("compact_ratio")?.jsonPrimitive?.double,
    )
  }

  @Test
  fun hyperArrowsSendDirectionalCycleCommands() {
    val launchers = manipulatorsFor("Hyper arrows cycle frontmost window layouts")
    val commands = launchers.map { assertNotNull(it.to?.single()?.sendUserCommand) }

    assertEquals(
        listOf(KeyCode.UpArrow, KeyCode.DownArrow, KeyCode.LeftArrow, KeyCode.RightArrow),
        launchers.map { it.from.keyCode },
    )
    assertHyperModifiers(launchers)
    assertEquals(List(4) { 2 }, commands.map { it.payload["version"]?.jsonPrimitive?.int })
    assertEquals(
        List(4) { "cycle_frontmost_window" },
        commands.map { it.payload["command"]?.jsonPrimitive?.content },
    )
    assertEquals(
        listOf("up", "down", "left", "right"),
        commands.map { it.payload["direction"]?.jsonPrimitive?.content },
    )
  }

  private fun manipulatorsFor(description: String): List<Manipulator> {
    val rule = createMainRules().single { it.description == description }
    return assertNotNull(rule.manipulators)
  }

  private fun assertHyperModifiers(manipulators: List<Manipulator>) {
    val hyperModifiers = listOf(RightControl, RightCommand, RightOption, RightShift)
    assertEquals(
        List(manipulators.size) { hyperModifiers },
        manipulators.map { it.from.modifiers?.mandatory },
    )
  }
}
