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
    assertEquals(List(7) { 3 }, commands.map { it.payload["version"]?.jsonPrimitive?.int })
    assertEquals(
        List(7) { "cycle_window_layout" },
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
        commands.map {
          it.payload["target"]?.jsonObject?.get("bundle_identifier")?.jsonPrimitive?.content
        },
    )
    assertEquals(
        listOf(1, 2, 2, 2, 1, 2, 2),
        commands.map { it.payload["layouts"]?.jsonArray?.size },
    )
    assertEquals(
        List(7) { "existing" },
        commands.map { it.payload["screen_strategy"]?.jsonPrimitive?.content },
    )
    val appTarget = commands.first().payload["target"]!!.jsonObject
    assertEquals(true, appTarget["open_if_needed"]?.jsonPrimitive?.content?.toBoolean())
    assertEquals(true, appTarget["activate"]?.jsonPrimitive?.content?.toBoolean())
    assertEquals(true, appTarget["activate_all_windows"]?.jsonPrimitive?.content?.toBoolean())
    assertEquals(
        true,
        appTarget["reset_cycle_when_not_frontmost"]?.jsonPrimitive?.content?.toBoolean(),
    )

    val browserCommand = commands[5]
    assertEquals("all", browserCommand.payload["window_scope"]?.jsonPrimitive?.content)
    assertEquals(
        48,
        browserCommand.payload["cascade_offset"]?.jsonObject?.get("x")?.jsonPrimitive?.int,
    )
    val browserFocusedLayout = browserCommand.payload["layouts"]!!.jsonArray[0].jsonObject
    assertEquals(
        0.28,
        browserFocusedLayout["insets"]
            ?.jsonObject
            ?.get("left")
            ?.jsonObject
            ?.get("fraction")
            ?.jsonPrimitive
            ?.double,
    )
    assertEquals(
        0.03,
        browserFocusedLayout["insets"]
            ?.jsonObject
            ?.get("top")
            ?.jsonObject
            ?.get("fraction")
            ?.jsonPrimitive
            ?.double,
    )
    assertEquals(
        240,
        browserFocusedLayout["insets"]
            ?.jsonObject
            ?.get("left")
            ?.jsonObject
            ?.get("points")
            ?.jsonPrimitive
            ?.int,
    )
    assertEquals(
        96,
        browserCommand.payload["layouts"]
            ?.jsonArray
            ?.get(1)
            ?.jsonObject
            ?.get("insets")
            ?.jsonObject
            ?.get("top")
            ?.jsonObject
            ?.get("points")
            ?.jsonPrimitive
            ?.int,
    )
    assertEquals(
        List(6) { "focused" },
        commands
            .filterIndexed { index, _ -> index != 5 }
            .map {
              it.payload["window_scope"]?.jsonPrimitive?.content
            },
    )

    val onePasswordLayout = commands.first().payload["layouts"]!!.jsonArray.single().jsonObject
    assertEquals(
        2.0 / 3.0,
        onePasswordLayout["insets"]
            ?.jsonObject
            ?.get("left")
            ?.jsonObject
            ?.get("fraction")
            ?.jsonPrimitive
            ?.double,
    )
    assertEquals(
        "right",
        onePasswordLayout["resize_anchor"]?.jsonObject?.get("horizontal")?.jsonPrimitive?.content,
    )
    assertEquals(
        "bottom",
        onePasswordLayout["resize_anchor"]?.jsonObject?.get("vertical")?.jsonPrimitive?.content,
    )

    val spotifyLayout = commands[4].payload["layouts"]!!.jsonArray.single().jsonObject
    assertEquals(800, spotifyLayout["minimum_width"]?.jsonPrimitive?.int)
    assertEquals(800, spotifyLayout["maximum_width"]?.jsonPrimitive?.int)
    assertEquals(
        "left",
        spotifyLayout["resize_anchor"]?.jsonObject?.get("horizontal")?.jsonPrimitive?.content,
    )

    assertEquals(
        listOf(-60, 120, -180),
        commands.slice(1..3).map {
          it.payload["layouts"]
              ?.jsonArray
              ?.get(0)
              ?.jsonObject
              ?.get("insets")
              ?.jsonObject
              ?.get("left")
              ?.jsonObject
              ?.get("points")
              ?.jsonPrimitive
              ?.int
        },
    )
    assertEquals(
        listOf(-24, 48, -72),
        commands.slice(1..3).map {
          it.payload["layouts"]
              ?.jsonArray
              ?.get(1)
              ?.jsonObject
              ?.get("insets")
              ?.jsonObject
              ?.get("top")
              ?.jsonObject
              ?.get("points")
              ?.jsonPrimitive
              ?.int
        },
    )

    val terminalLayouts = commands.last().payload["layouts"]!!.jsonArray
    assertEquals(
        0.12,
        terminalLayouts[0]
            .jsonObject["insets"]
            ?.jsonObject
            ?.get("left")
            ?.jsonObject
            ?.get("fraction")
            ?.jsonPrimitive
            ?.double,
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
    assertEquals(List(4) { 3 }, commands.map { it.payload["version"]?.jsonPrimitive?.int })
    assertEquals(
        List(4) { "cycle_window_layout" },
        commands.map { it.payload["command"]?.jsonPrimitive?.content },
    )
    assertEquals(
        listOf("direction:up", "direction:down", "direction:left", "direction:right"),
        commands.map { it.payload["cycle_id"]?.jsonPrimitive?.content },
    )
    assertEquals(listOf(2, 2, 3, 3), commands.map { it.payload["layouts"]?.jsonArray?.size })
    assertEquals(
        0.5,
        commands[0]
            .payload["layouts"]
            ?.jsonArray
            ?.get(0)
            ?.jsonObject
            ?.get("insets")
            ?.jsonObject
            ?.get("bottom")
            ?.jsonObject
            ?.get("fraction")
            ?.jsonPrimitive
            ?.double,
    )
    assertEquals(
        0.5,
        commands[3]
            .payload["layouts"]
            ?.jsonArray
            ?.get(0)
            ?.jsonObject
            ?.get("insets")
            ?.jsonObject
            ?.get("left")
            ?.jsonObject
            ?.get("fraction")
            ?.jsonPrimitive
            ?.double,
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
