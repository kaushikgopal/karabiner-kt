package sh.kau.karabiner

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlinx.serialization.json.boolean
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
        listOf(
            KeyCode.Num1,
            KeyCode.M,
            KeyCode.W,
            KeyCode.O,
            KeyCode.S,
            KeyCode.Num0,
            KeyCode.B,
            KeyCode.T,
        ),
        launchers.map { it.from.keyCode },
    )
    assertHyperModifiers(launchers)
    assertEquals(List(8) { 3 }, commands.map { it.payload["version"]?.jsonPrimitive?.int })
    assertEquals(
        List(8) { "cycle_window_layout" },
        commands.map { it.payload["command"]?.jsonPrimitive?.content },
    )
    assertEquals(
        listOf(
            "com.1password.1password",
            "com.apple.MobileSMS",
            "net.whatsapp.WhatsApp",
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
        listOf(1, 2, 2, 2, 2, 1, 2, 2),
        commands.map { it.payload["layouts"]?.jsonArray?.size },
    )
    assertEquals(
        List(8) { "existing" },
        commands.map { it.payload["screen_strategy"]?.jsonPrimitive?.content },
    )
    val appTarget = commands.first().payload["target"]!!.jsonObject
    assertEquals(true, appTarget["open_if_needed"]?.jsonPrimitive?.content?.toBoolean())
    assertEquals(true, appTarget["activate"]?.jsonPrimitive?.content?.toBoolean())
    assertEquals(true, appTarget["activate_all_windows"]?.jsonPrimitive?.content?.toBoolean())

    commands.forEach { assertSharedPolicyGroups(it) }
    commands.forEach { assertCyclePolicy(it, resetWhenTargetNotFrontmost = true) }

    val browserCommand = commands[6]
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
        List(7) { "focused" },
        commands
            .filterIndexed { index, _ -> index != 6 }
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

    val spotifyLayout = commands[5].payload["layouts"]!!.jsonArray.single().jsonObject
    assertEquals(800, spotifyLayout["minimum_width"]?.jsonPrimitive?.int)
    assertEquals(800, spotifyLayout["maximum_width"]?.jsonPrimitive?.int)
    assertEquals(
        "left",
        spotifyLayout["resize_anchor"]?.jsonObject?.get("horizontal")?.jsonPrimitive?.content,
    )

    assertEquals(
        listOf(-60, 60, 120, -180),
        commands.slice(1..4).map {
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
        listOf(-24, 24, 48, -72),
        commands.slice(1..4).map {
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

    commands.forEach { assertSharedPolicyGroups(it) }
    commands.forEach { assertCyclePolicy(it, resetWhenTargetNotFrontmost = false) }
  }

  @Test
  fun hyperFCyclesMaximizeCenteredAlmostFullAndRestore() {
    val launchers =
        manipulatorsFor("Hyper F cycles frontmost window maximize / centered 90% / restore")
    val commands = launchers.map { assertNotNull(it.to?.single()?.sendUserCommand) }

    assertEquals(listOf(KeyCode.F), launchers.map { it.from.keyCode })
    assertHyperModifiers(launchers)
    assertEquals(
        listOf("fill"), commands.map { it.payload["cycle_id"]?.jsonPrimitive?.content })
    assertEquals(
        listOf("frontmost"),
        commands.map { it.payload["target"]?.jsonObject?.get("type")?.jsonPrimitive?.content },
    )

    val layouts = commands.single().payload["layouts"]!!.jsonArray
    assertEquals(3, layouts.size)

    val maximized = layouts[0].jsonObject
    listOf("left", "top", "right", "bottom").forEach { side ->
      assertEquals(
          0.0,
          maximized["insets"]
              ?.jsonObject
              ?.get(side)
              ?.jsonObject
              ?.get("fraction")
              ?.jsonPrimitive
              ?.double,
      )
    }
    assertNull(maximized["restore_original"])

    val almostFullScreen = layouts[1].jsonObject
    listOf("left", "top", "right", "bottom").forEach { side ->
      assertEquals(
          0.05,
          almostFullScreen["insets"]
              ?.jsonObject
              ?.get(side)
              ?.jsonObject
              ?.get("fraction")
              ?.jsonPrimitive
              ?.double,
      )
    }
    assertEquals(
        "center",
        almostFullScreen["resize_anchor"]?.jsonObject?.get("horizontal")?.jsonPrimitive?.content,
    )
    assertEquals(
        "center",
        almostFullScreen["resize_anchor"]?.jsonObject?.get("vertical")?.jsonPrimitive?.content,
    )

    val restore = layouts[2].jsonObject
    assertEquals(true, restore["restore_original"]?.jsonPrimitive?.boolean)

    commands.forEach { assertSharedPolicyGroups(it) }
    commands.forEach { assertCyclePolicy(it, resetWhenTargetNotFrontmost = false) }
  }

  private fun manipulatorsFor(description: String): List<Manipulator> {
    val rule = createMainRules().single { it.description == description }
    return assertNotNull(rule.manipulators)
  }

  private fun assertSharedPolicyGroups(command: SendUserCommand) {
    val payload = command.payload
    val windowFilter = payload["window_filter"]?.jsonObject
    assertNotNull(windowFilter)
    assertEquals(true, windowFilter["standard_only"]?.jsonPrimitive?.boolean)
    assertEquals(true, windowFilter["reject_minimized"]?.jsonPrimitive?.boolean)
    assertEquals(true, windowFilter["reject_fullscreen"]?.jsonPrimitive?.boolean)

    val focusAfterLayout = payload["focus_after_layout"]?.jsonObject
    assertNotNull(focusAfterLayout)
    assertEquals(true, focusAfterLayout["raise_window"]?.jsonPrimitive?.boolean)
    assertEquals(true, focusAfterLayout["refocus_window"]?.jsonPrimitive?.boolean)

    val timeouts = payload["timeouts"]?.jsonObject
    assertNotNull(timeouts)
    assertEquals(1.0, timeouts["ax_messaging_timeout_seconds"]?.jsonPrimitive?.double)
    assertEquals(5000, timeouts["application_wait_timeout_milliseconds"]?.jsonPrimitive?.int)
    assertEquals(5000, timeouts["focused_window_wait_timeout_milliseconds"]?.jsonPrimitive?.int)
    assertEquals(25, timeouts["poll_interval_milliseconds"]?.jsonPrimitive?.int)
  }

  private fun assertCyclePolicy(command: SendUserCommand, resetWhenTargetNotFrontmost: Boolean) {
    val cyclePolicy = command.payload["cycle_policy"]?.jsonObject
    assertNotNull(cyclePolicy)
    assertEquals(true, cyclePolicy["reset_on_application_change"]?.jsonPrimitive?.boolean)
    assertEquals(true, cyclePolicy["reset_on_focused_window_change"]?.jsonPrimitive?.boolean)
    assertEquals(
        resetWhenTargetNotFrontmost,
        cyclePolicy["reset_when_target_not_frontmost"]?.jsonPrimitive?.boolean,
    )
  }

  private fun assertHyperModifiers(manipulators: List<Manipulator>) {
    val hyperModifiers = listOf(RightControl, RightCommand, RightOption, RightShift)
    assertEquals(
        List(manipulators.size) { hyperModifiers },
        manipulators.map { it.from.modifiers?.mandatory },
    )
  }
}
