package sh.kau.karabiner

import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import sh.kau.karabiner.KeyCode.DownArrow
import sh.kau.karabiner.KeyCode.LeftArrow
import sh.kau.karabiner.KeyCode.RightArrow
import sh.kau.karabiner.KeyCode.UpArrow
import sh.kau.karabiner.ModifierKeyCode.LeftCommand
import sh.kau.karabiner.ModifierKeyCode.LeftControl
import sh.kau.karabiner.ModifierKeyCode.LeftOption
import sh.kau.karabiner.ModifierKeyCode.LeftShift
import sh.kau.karabiner.ModifierKeyCode.RightCommand
import sh.kau.karabiner.ModifierKeyCode.RightControl
import sh.kau.karabiner.ModifierKeyCode.RightOption
import sh.kau.karabiner.ModifierKeyCode.RightShift

private data class RelativeInset(
    val fraction: Double = 0.0,
    val points: Int = 0,
)

private data class WindowLayout(
    val left: RelativeInset = RelativeInset(),
    val top: RelativeInset = RelativeInset(),
    val right: RelativeInset = RelativeInset(),
    val bottom: RelativeInset = RelativeInset(),
    val horizontalAnchor: String = "center",
    val verticalAnchor: String = "center",
)

private data class AppWindowShortcut(
    val key: KeyCode,
    val bundleIdentifier: String,
    val layouts: List<WindowLayout>,
    val windowScope: String,
    val cascadeOffset: Int,
)

private data class DirectionalWindowShortcut(
    val key: KeyCode,
    val direction: String,
    val layouts: List<WindowLayout>,
)

private fun centeredLayout(horizontalGap: Double, verticalGap: Double) =
    WindowLayout(
        left = RelativeInset(horizontalGap),
        top = RelativeInset(verticalGap),
        right = RelativeInset(horizontalGap),
        bottom = RelativeInset(verticalGap),
    )

private val focusedLayout = centeredLayout(horizontalGap = 0.25, verticalGap = 0.05)

private val wideLayout = centeredLayout(horizontalGap = 0.05, verticalGap = 0.10)

private val terminalFocusedLayout = centeredLayout(horizontalGap = 0.12, verticalGap = 0.05)

private val browserFocusedLayout = centeredLayout(horizontalGap = 0.28, verticalGap = 0.03)

private fun appWindowShortcut(
    key: KeyCode,
    bundleIdentifier: String,
    layouts: List<WindowLayout> = listOf(focusedLayout, wideLayout),
    windowScope: String = "focused",
    cascadeOffset: Int = 0,
) = AppWindowShortcut(key, bundleIdentifier, layouts, windowScope, cascadeOffset)

private val appWindowShortcuts =
    listOf(
        appWindowShortcut(KeyCode.Num1, "com.1password.1password"),
        appWindowShortcut(KeyCode.M, "com.apple.MobileSMS"),
        appWindowShortcut(KeyCode.O, "md.obsidian"),
        appWindowShortcut(KeyCode.S, "com.tinyspeck.slackmacgap"),
        appWindowShortcut(KeyCode.Num0, "com.spotify.client"),
        appWindowShortcut(
            KeyCode.B,
            "net.imput.helium",
            layouts = listOf(browserFocusedLayout, wideLayout),
            windowScope = "all",
            cascadeOffset = 48,
        ),
        appWindowShortcut(
            KeyCode.T,
            "com.mitchellh.ghostty",
            layouts = listOf(terminalFocusedLayout, wideLayout),
        ),
    )

private val directionalWindowShortcuts =
    listOf(
        DirectionalWindowShortcut(
            KeyCode.UpArrow,
            "up",
            listOf(
                WindowLayout(
                    bottom = RelativeInset(0.5),
                    horizontalAnchor = "left",
                    verticalAnchor = "top",
                ),
                WindowLayout(
                    bottom = RelativeInset(1.0 / 3.0),
                    horizontalAnchor = "left",
                    verticalAnchor = "top",
                ),
            ),
        ),
        DirectionalWindowShortcut(
            KeyCode.DownArrow,
            "down",
            listOf(
                WindowLayout(
                    top = RelativeInset(0.5),
                    horizontalAnchor = "left",
                    verticalAnchor = "bottom",
                ),
                WindowLayout(
                    top = RelativeInset(1.0 / 3.0),
                    horizontalAnchor = "left",
                    verticalAnchor = "bottom",
                ),
            ),
        ),
        DirectionalWindowShortcut(
            KeyCode.LeftArrow,
            "left",
            listOf(
                WindowLayout(
                    right = RelativeInset(0.5),
                    horizontalAnchor = "left",
                    verticalAnchor = "top",
                ),
                WindowLayout(
                    right = RelativeInset(2.0 / 3.0),
                    horizontalAnchor = "left",
                    verticalAnchor = "top",
                ),
                WindowLayout(
                    right = RelativeInset(1.0 / 3.0),
                    horizontalAnchor = "left",
                    verticalAnchor = "top",
                ),
            ),
        ),
        DirectionalWindowShortcut(
            KeyCode.RightArrow,
            "right",
            listOf(
                WindowLayout(
                    left = RelativeInset(0.5),
                    horizontalAnchor = "right",
                    verticalAnchor = "top",
                ),
                WindowLayout(
                    left = RelativeInset(2.0 / 3.0),
                    horizontalAnchor = "right",
                    verticalAnchor = "top",
                ),
                WindowLayout(
                    left = RelativeInset(1.0 / 3.0),
                    horizontalAnchor = "right",
                    verticalAnchor = "top",
                ),
            ),
        ),
    )

private fun AppWindowShortcut.toUserCommand() =
    SendUserCommand(
        payload =
            buildJsonObject {
              put("version", 3)
              put("command", "cycle_window_layout")
              put("cycle_id", "app:$bundleIdentifier")
              put(
                  "target",
                  buildJsonObject {
                    put("type", "application")
                    put("bundle_identifier", bundleIdentifier)
                    put("open_if_needed", true)
                    put("activate", true)
                    put("activate_all_windows", true)
                    put("reset_cycle_when_not_frontmost", true)
                  },
              )
              put("screen_strategy", "existing")
              put("screen_frame", "visible")
              put("window_scope", windowScope)
              put(
                  "cascade_offset",
                  buildJsonObject {
                    put("x", cascadeOffset)
                    put("y", cascadeOffset)
                  },
              )
              put(
                  "layouts",
                  buildJsonArray {
                    layouts.forEach { add(it.toJson()) }
                  },
              )
            },
    )

private fun DirectionalWindowShortcut.toUserCommand() =
    SendUserCommand(
        payload =
            buildJsonObject {
              put("version", 3)
              put("command", "cycle_window_layout")
              put("cycle_id", "direction:$direction")
              put("target", buildJsonObject { put("type", "frontmost") })
              put("screen_strategy", "existing")
              put("screen_frame", "visible")
              put("window_scope", "focused")
              put(
                  "cascade_offset",
                  buildJsonObject {
                    put("x", 0)
                    put("y", 0)
                  },
              )
              put(
                  "layouts",
                  buildJsonArray {
                    layouts.forEach { add(it.toJson()) }
                  },
              )
            },
    )

private fun WindowLayout.toJson() = buildJsonObject {
  put(
      "insets",
      buildJsonObject {
        put("left", left.toJson())
        put("top", top.toJson())
        put("right", right.toJson())
        put("bottom", bottom.toJson())
      },
  )
  put(
      "resize_anchor",
      buildJsonObject {
        put("horizontal", horizontalAnchor)
        put("vertical", verticalAnchor)
      },
  )
}

private fun RelativeInset.toJson() = buildJsonObject {
  put("fraction", fraction)
  put("points", points)
}

// Note: The final karabinerConfig construction and JSON writing will be in Main.kt

fun createMainRules(): List<KarabinerRule> {

  // hyper = right-side cmd+ctrl+opt+shift (keeps left-side modifiers free for combining).
  // expressed as 4 explicit modifiers (not the virtual "hyper" key code) so that
  // to_if_alone (escape) fires reliably on tap — the virtual key code leaks the
  // original caps_lock event and toggles the LED instead.
  val newCapsLockModifiers: List<ModifierKeyCode> =
      listOf(RightControl, RightCommand, RightOption, RightShift)

  return listOf(

      // right command -> right control (global, straight remap)
      karabinerRuleSingle {
        description = "Right Command -> Right Control (global)"
        fromKey = RightCommand
        toKey = RightControl
      },

      // Kinesis keyboards
      // karabinerRule {
      //   description = "Kinesis keyboard specific mappings"
      //   mapping {
      //     fromKey = KeyCode.EqualSign
      //     toKey = KeyCode.GraveAccentAndTilde
      //     forDevice { identifiers = listOf(DeviceIdentifier.KINESIS) }
      //   }
      // },

      karabinerRule {
        description = "Hyper app launchers with cycling window layouts"
        appWindowShortcuts.forEach { shortcut ->
          mapping {
            fromKey = shortcut.key
            fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
            sendUserCommand = shortcut.toUserCommand()
          }
        }
      },
      karabinerRule {
        description = "Hyper arrows cycle frontmost window layouts"
        directionalWindowShortcuts.forEach { shortcut ->
          mapping {
            fromKey = shortcut.key
            fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
            sendUserCommand = shortcut.toUserCommand()
          }
        }
      },

      // hyper + vim movements (jklp) ~= quick arrow keys (tries to accommodate modifiers)
      *createVimNavigationRules(newCapsLockModifiers),

      // capslock (hyper) + shift + arrow = ctrl + shift + arrow
      // (hyper swallows shift into a 5-modifier event, so we remap explicitly)
      karabinerRule {
        description = "Caps Lock + Left Shift + Arrow = Ctrl + Left Shift + Arrows"
        mapping {
          fromKey = KeyCode.UpArrow
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers + LeftShift)
          toKey = KeyCode.UpArrow
          toModifiers = listOf(LeftShift, LeftControl)
        }
        mapping {
          fromKey = KeyCode.DownArrow
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers + LeftShift)
          toKey = KeyCode.DownArrow
          toModifiers = listOf(LeftShift, LeftControl)
        }
        mapping {
          fromKey = KeyCode.LeftArrow
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers + LeftShift)
          toKey = KeyCode.LeftArrow
          toModifiers = listOf(LeftShift, LeftControl)
        }
        mapping {
          fromKey = KeyCode.RightArrow
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers + LeftShift)
          toKey = KeyCode.RightArrow
          toModifiers = listOf(LeftShift, LeftControl)
        }
      },

      // capslock (hyper) key is different and can't be added as simple layer key rules
      karabinerRuleSingle {
        description = "Caps Lock alone -> Escape, held -> Hyper"
        fromKey = KeyCode.CapsLock
        toKey = newCapsLockModifiers.first()
        toModifiers = newCapsLockModifiers.drop(1).takeIf { it.isNotEmpty() }
        toKeyIfAlone = KeyCode.Escape
        unlessApp { bundleIds = listOf("^md\\.obsidian") }
      },
      karabinerRuleSingle {
        description = "Caps Lock alone -> Escape * 2, held -> Hyper (Obsidian)"
        fromKey = KeyCode.CapsLock
        toKey = newCapsLockModifiers.first()
        toModifiers = newCapsLockModifiers.drop(1).takeIf { it.isNotEmpty() }
        toKeysIfAlone = listOf(KeyCode.Escape, KeyCode.Escape)
        forApp { bundleIds = listOf("^md\\.obsidian") }
      },

      // delete sequences
      karabinerRule {
        description = "(J layer) delete sequences"
        layerKey = KeyCode.J

        // ---------------------
        // DELETE sequences

        // delete word
        mapping {
          fromKey = KeyCode.D
          toKey = KeyCode.W
          toModifiers = listOf(LeftControl)
          forApp {
            bundleIds =
                listOf(
                    "^com\\.apple\\.Terminal$",
                    "^com\\.googlecode\\.iterm2$",
                    "^com\\.mitchellh\\.ghostty$",
                    "^com\\.cmuxterm\\.app$",
                )
          }
        }
        mapping {
          fromKey = KeyCode.D
          toKey = KeyCode.DeleteOrBackspace
          toModifiers = listOf(LeftOption)
          unlessApp {
            bundleIds =
                listOf(
                    "^com\\.apple\\.Terminal$",
                    "^com\\.googlecode\\.iterm2$",
                    "^com\\.mitchellh\\.ghostty$",
                    "^com\\.cmuxterm\\.app$",
                )
          }
        }

        // delete character
        mapping {
          fromKey = KeyCode.F
          toKey = KeyCode.DeleteOrBackspace
        }
      },

      // bracket sequences
      karabinerRule {
        description = "(F layer) bracket sequences"
        layerKey = KeyCode.F

        // U I
        // ( )
        mapping {
          fromKey = KeyCode.U
          toKey = KeyCode.Num9
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.I
          toKey = KeyCode.Num0
          toModifiers = listOf(LeftShift)
        }

        // J K
        // [ ]
        mapping {
          fromKey = KeyCode.J
          toKey = KeyCode.OpenBracket
        }
        mapping {
          fromKey = KeyCode.K
          toKey = KeyCode.CloseBracket
        }

        // M ,
        // { }
        mapping {
          fromKey = KeyCode.M
          toKey = KeyCode.OpenBracket
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.Comma
          toKey = KeyCode.CloseBracket
          toModifiers = listOf(LeftShift)
        }

        // . /
        // < >
        mapping {
          fromKey = KeyCode.Period
          toKey = KeyCode.Comma
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.Slash
          toKey = KeyCode.Period
          toModifiers = listOf(LeftShift)
        }
      },

      // ring finger sequences: (s) -> #, (a) -> *
      karabinerRuleSingle {
        description = "J + S -> #"
        layerKey = KeyCode.J
        fromKey = KeyCode.S
        toKey = KeyCode.Num3
        toModifiers = listOf(LeftShift)
      },
      karabinerRuleSingle {
        description = "J + A -> *"
        layerKey = KeyCode.J
        fromKey = KeyCode.A
        toKey = KeyCode.Num8
        toModifiers = listOf(LeftShift)
      },

      // J layer - special characters (vim sequences)
      // E - $
      // R - %
      // T - ^
      karabinerRule {
        description = "(J layer) special character sequences (vim sequences)"
        layerKey = KeyCode.J

        mapping {
          fromKey = KeyCode.E
          toKey = KeyCode.Num4
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.R
          toKey = KeyCode.Num5
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.T
          toKey = KeyCode.Num6
          toModifiers = listOf(LeftShift)
        }
      },
      karabinerRule {
        description = "(J layer) misc special characters"
        layerKey = KeyCode.J

        // Q
        // @
        mapping {
          fromKey = KeyCode.Q
          toKey = KeyCode.Num2
          toModifiers = listOf(LeftShift)
        }

        // 1
        // !
        mapping {
          fromKey = KeyCode.Num1
          toKey = KeyCode.Num1
          toModifiers = listOf(LeftShift)
        }
        // 2
        // @
        mapping {
          fromKey = KeyCode.Num2
          toKey = KeyCode.Num2
          toModifiers = listOf(RightShift)
        }

        // J + C - cmd shift [
        // J + V - cmd shift ]
        // cmd shift [ + ] - for quick tab switching
        mapping {
          fromKey = KeyCode.C
          toKey = KeyCode.OpenBracket
          toModifiers = listOf(LeftCommand, LeftShift)
        }
        mapping {
          fromKey = KeyCode.V
          toKey = KeyCode.CloseBracket
          toModifiers = listOf(LeftCommand, LeftShift)
        }
      },

      // f layer - special character sequences
      karabinerRule {
        description = "(F layer) special character sequences"
        layerKey = KeyCode.F

        // F + Y = &
        mapping {
          fromKey = KeyCode.Y
          toKey = KeyCode.Num7
          toModifiers = listOf(LeftShift)
        }

        //  O     L   ;   '
        //  =     +   -   \
        mapping {
          fromKey = KeyCode.O
          toKey = KeyCode.EqualSign
        }

        mapping {
          fromKey = KeyCode.L
          toKey = KeyCode.EqualSign
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.Semicolon
          toKey = KeyCode.Hyphen
        }
        mapping {
          fromKey = KeyCode.Quote
          toKey = KeyCode.Backslash
        }
      },
  )
}

/** Creates manipulators for vim-style navigation with various modifier combinations */
fun createVimNavigationRules(newCapsLockModifiers: List<ModifierKeyCode>): Array<KarabinerRule> {
  val rules = mutableListOf<KarabinerRule>()

  // important for position in list between the two
  val arrowKeys: List<KeyCode> = listOf(LeftArrow, DownArrow, UpArrow, RightArrow)
  val vimNavKeys: List<KeyCode> = listOf(KeyCode.H, KeyCode.J, KeyCode.K, KeyCode.L)

  // map capsLock + (below list of modifier combo) + vim keys
  //     capsLock + (below list of modifier combo) + arrow keys
  arrayOf(
          null,
          listOf(LeftCommand),
          listOf(LeftOption),
          listOf(LeftShift),
          listOf(LeftCommand, LeftOption),
          listOf(LeftCommand, LeftShift),
      )
      .forEach { modifiers ->
        vimNavKeys.forEachIndexed { index, vimKey ->
          val fromModifierList = newCapsLockModifiers + (modifiers ?: emptyList<ModifierKeyCode>())
          val fromModifierListDesc =
              fromModifierList.joinToString(" + ") { it::class.simpleName.toString() }
          val desc =
              "CapsLock + $fromModifierListDesc + ${vimKey::class.simpleName} -> ${arrowKeys[index]::class.simpleName}"

          rules.add(
              karabinerRuleSingle {
                description = desc
                fromKey = vimKey
                fromModifiers = FromModifiers(mandatory = fromModifierList)
                toKey = arrowKeys[index]
                toModifiers = modifiers
              },
          )
        }
      }

  return rules.toTypedArray()
}

/**
 * temporarily disabled as i don't use it as much and would rather use it for more prevalent
 * commands
 */
fun capsLockMouseRules(newCapsLockModifiers: List<ModifierKeyCode>): Array<KarabinerRule> {
  val rules = mutableListOf<KarabinerRule>()
  // Mouse control with arrow keys
  listOf(
          Pair(DownArrow, MouseKey(y = 1536)),
          Pair(UpArrow, MouseKey(y = -1536)),
          Pair(LeftArrow, MouseKey(x = -1536)),
          Pair(RightArrow, MouseKey(x = 1536)),
      )
      .forEach { (fromKey, mouseKeyValue) ->
        rules.add(
            karabinerRuleSingle {
              description = "CapsLock + ${fromKey.name} -> Move Mouse Cursor"
              this.fromKey = fromKey
              fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
              mouseKey = mouseKeyValue
            },
        )
      }

  rules.add(
      karabinerRule {
        description = "CapsLock (+ Command) +  Enter -> Mouse (Secondary) Click Buttons"
        mapping {
          fromKey = KeyCode.ReturnOrEnter
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          pointingButton = "button1"
        }
        mapping {
          fromKey = KeyCode.ReturnOrEnter
          fromModifiers = FromModifiers(mandatory = listOf(LeftCommand) + newCapsLockModifiers)
          pointingButton = "button2"
        }
      }
  )

  return rules.toTypedArray()
}
