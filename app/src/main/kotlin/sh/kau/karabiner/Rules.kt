package sh.kau.karabiner

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

// Note: The final karabinerConfig construction and JSON writing will be in Main.kt

fun createMainRules(): List<KarabinerRule> {

  // explicitly mapping to right side modifiers
  // as i find myself using the (left) capslock + left modifiers
  // if i already use left-modifier for capslock hyper
  // karabiner won't see those
  val newCapsLockModifiers = listOf(RightControl, RightCommand, RightOption, RightShift)

  return listOf(
      karabinerRule {
        description = "Right Cmd -> Ctrl Enter (alone)"
        mapping {
          fromKey = RightCommand
          toKey = RightControl
          // toKeyIfAlone = KeyCode.ReturnOrEnter
          forDevice { identifiers = DeviceIdentifier.APPLE_KEYBOARDS }
        }
      },
      *createVimNavigationRules(newCapsLockModifiers),

    // capslock (hyper) keys are different and can't be added as simple layer key rules
      karabinerRuleSingle {
        description = "Caps Lock alone -> Escape, held -> Hyper(♦)"
        fromKey = KeyCode.CapsLock
        toKey = newCapsLockModifiers.first()
        toModifiers = newCapsLockModifiers.drop(1).takeIf { it.isNotEmpty() }
        toKeyIfAlone = KeyCode.Escape
        unlessApp { bundleIds = listOf("^md\\.obsidian") }
      },
      karabinerRuleSingle {
        description = "Caps Lock alone -> Escape, held -> Hyper(♦)"
        fromKey = KeyCode.CapsLock
        toKey = newCapsLockModifiers.first()
        toModifiers = newCapsLockModifiers.drop(1).takeIf { it.isNotEmpty() }
        toKeysIfAlone = listOf(KeyCode.Escape, KeyCode.Escape)
        forApp { bundleIds = listOf("^md\\.obsidian") }
      },
      karabinerRule {
        description = "Hyper(♦) Key launches"
        mapping {
          fromKey = KeyCode.C
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -g raycast://extensions/raycast/raycast/confetti"
        }
        mapping {
          fromKey = KeyCode.Num0
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Ghostty.app'"
        }
        mapping {
          fromKey = KeyCode.Num9 // slack
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Slack.app'"
        }
        mapping {
          fromKey = KeyCode.Num5
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Music.app'"
        }
        mapping {
          fromKey = KeyCode.A
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open raycast://extensions/raycast/raycast-ai/ai-chat"
        }
        mapping {
          fromKey = KeyCode.D   // desktop
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Mission Control.app' --args 1"
        }
        mapping {
          fromKey = KeyCode.F
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Finder.app'"
        }
        mapping {
          fromKey = KeyCode.I
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Firefox.app'"
        }
        mapping {
          fromKey = KeyCode.M   // mission control
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Mission Control.app' --args 3"
        }
        mapping {
          fromKey = KeyCode.N   // app expose
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Mission Control.app' --args 2"
        }
        mapping {
          fromKey = KeyCode.O
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a Obsidian.app"
        }
        mapping {
          fromKey = KeyCode.S
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Android Studio.app'"
        }
        mapping {
          fromKey = KeyCode.U
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'Cursor.app'"
        }
        mapping {
          fromKey = KeyCode.W
          fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
          shellCommand = "open -a 'WhatsApp.app'"
        }
      },
      karabinerRule {
        description = "F-key layer mappings"
        layerKey = KeyCode.F

        // --- mapped to right hand side Shift num keys -
        //   Y U I
        //   ^ & *
        mapping {
          fromKey = KeyCode.Y
          toKey = KeyCode.Num6
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.U
          toKey = KeyCode.Num7
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.I
          toKey = KeyCode.Num8
          toModifiers = listOf(LeftShift)
        }

        // special one - \
        mapping {
          fromKey = KeyCode.O
          toKey = KeyCode.Backslash
        }

        // special one - |
        mapping {
          fromKey = KeyCode.P
          toKey = KeyCode.Backslash
          toModifiers = listOf(LeftShift)
        }

        // special ones
        //  L ; '
        //  - = +
        mapping {
          fromKey = KeyCode.L
          toKey = KeyCode.Hyphen
        }
        mapping {
          fromKey = KeyCode.Semicolon
          toKey = KeyCode.EqualSign
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.Quote
          toKey = KeyCode.EqualSign
        }

        // J K
        // ( )
        mapping {
          fromKey = KeyCode.J
          toKey = KeyCode.Num9
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.K
          toKey = KeyCode.Num0
          toModifiers = listOf(LeftShift)
        }

        // M ,
        // [ ]
        mapping {
          fromKey = KeyCode.M
          toKey = KeyCode.OpenBracket
        }
        mapping {
          fromKey = KeyCode.Comma
          toKey = KeyCode.CloseBracket
        }

        // . /
        // { }
        mapping {
          fromKey = KeyCode.Period
          toKey = KeyCode.OpenBracket
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.Slash
          toKey = KeyCode.CloseBracket
          toModifiers = listOf(LeftShift)
        }
      },
      karabinerRule {
        description = "J-key layer mappings"
        layerKey = KeyCode.J

        // T R E W Q
        // % $ # @ !
        mapping {
          fromKey = KeyCode.T
          toKey = KeyCode.Num5
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.R
          toKey = KeyCode.Num4
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.E
          toKey = KeyCode.Num3
          toModifiers = listOf(LeftShift)
        }

        mapping {
          fromKey = KeyCode.W
          toKey = KeyCode.Num2
          toModifiers = listOf(LeftShift)
        }
        mapping {
          fromKey = KeyCode.Q
          toKey = KeyCode.Num1
          toModifiers = listOf(LeftShift)
        }

        // Delete sequences

        // delete line
        mapping {
          fromKey = KeyCode.S
          toKey = KeyCode.U
          toModifiers = listOf(LeftControl)
          forApp { bundleIds = listOf("^com\\.apple\\.Terminal$", "^com\\.googlecode\\.iterm2$") }
        }
        mapping {
          fromKey = KeyCode.S
          toKey = KeyCode.DeleteOrBackspace
          toModifiers = listOf(LeftCommand)
          unlessApp {
            bundleIds = listOf("^com\\.apple\\.Terminal$", "^com\\.googlecode\\.iterm2$")
          }
        }

        // delete word
        mapping {
          fromKey = KeyCode.D
          toKey = KeyCode.W
          toModifiers = listOf(LeftControl)
          forApp { bundleIds = listOf("^com\\.apple\\.Terminal$", "^com\\.googlecode\\.iterm2$") }
        }
        mapping {
          fromKey = KeyCode.D
          toKey = KeyCode.DeleteOrBackspace
          toModifiers = listOf(LeftOption)
          unlessApp {
            bundleIds = listOf("^com\\.apple\\.Terminal$", "^com\\.googlecode\\.iterm2$")
          }
        }

        // delete character
        mapping {
          fromKey = KeyCode.F
          toKey = KeyCode.DeleteOrBackspace
        }

        // cmd shift [ + ] - for quick tab switching
        mapping {
          fromKey = KeyCode.X
          toKey = KeyCode.OpenBracket
          toModifiers = listOf(LeftCommand, LeftShift)
        }
        mapping {
          fromKey = KeyCode.C
          toKey = KeyCode.CloseBracket
          toModifiers = listOf(LeftCommand, LeftShift)
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
      })

  return rules.toTypedArray()
}
