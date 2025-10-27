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

        // Apple keyboards
        karabinerRule {
            description = "Right Cmd -> Ctrl Enter (alone)"
            mapping {
                fromKey = RightCommand
                toKey = RightControl
                // toKeyIfAlone = KeyCode.ReturnOrEnter
                forDevice { identifiers = DeviceIdentifier.APPLE_KEYBOARDS }
            }
        },

        // Kinesis keyboards
        karabinerRule {
            description = "Kinesis keyboard specific mappings"
            mapping {
                fromKey = KeyCode.EqualSign
                toKey = KeyCode.GraveAccentAndTilde
                forDevice { identifiers = listOf(DeviceIdentifier.KINESIS) }
            }
        },

        // hyper + vim movements (jklp) ~= quick arrow keys (tries to accommodate modifiers)
        *createVimNavigationRules(newCapsLockModifiers),

        // hyper + shift + arrow = ctrl + shift + arrow
        karabinerRule {
            // particularly important for ctrl + shift + ↑ ↓
            // which i use for expand/shrink selection in ides
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
            description = "Caps Lock alone -> Escape, held -> Hyper(♦)"
            fromKey = KeyCode.CapsLock
            toKey = newCapsLockModifiers.first()
            toModifiers = newCapsLockModifiers.drop(1).takeIf { it.isNotEmpty() }
            toKeyIfAlone = KeyCode.Escape
            unlessApp { bundleIds = listOf("^md\\.obsidian") }
        },
        karabinerRuleSingle {
            description = "Caps Lock alone -> Escape * 2 (for Obsidian alone)"
            fromKey = KeyCode.CapsLock
            toKey = newCapsLockModifiers.first()
            toModifiers = newCapsLockModifiers.drop(1).takeIf { it.isNotEmpty() }
            toKeysIfAlone = listOf(KeyCode.Escape, KeyCode.Escape)
            forApp { bundleIds = listOf("^md\\.obsidian") }
        },

        // hyper key quick launches
        karabinerRule {
            description = "Hyper(♦) Key launches"
            // mapping {
            //     fromKey = KeyCode.C
            //     fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
            //     shellCommand = "open -g raycast://extensions/raycast/raycast/confetti"
            // }
            mapping {
                // ; -> Ghostty (most used)
                fromKey = KeyCode.Semicolon
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'Ghostty.app'"
            }
            mapping {
                // 0 -> zed
                fromKey = KeyCode.Num0
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'Zed.app'"
            }
            mapping {
                // M(u)sic
                fromKey = KeyCode.U
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'Music.app'"
            }
            mapping {
                // (O)bsidian
                fromKey = KeyCode.O
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a Obsidian.app"
            }
            mapping {
                // F(i)refox
                fromKey = KeyCode.I
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = openAllWindowsForApp("Firefox")
            }
            mapping {
                // (A)I Chat - with Raycast
                fromKey = KeyCode.A
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open raycast://extensions/raycast/raycast-ai/ai-chat"
            }
            mapping {
                // Android (S)tudio
                fromKey = KeyCode.S
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = openAllWindowsForApp("Android Studio")
            }
            mapping {
                // (W)hatsapp
                fromKey = KeyCode.W
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'WhatsApp.app'"
            }
            mapping {
                // (F)inder
                fromKey = KeyCode.F
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = openAllWindowsForApp("Finder")
            }
            mapping {
                // (D)esktop
                fromKey = KeyCode.D
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'Mission Control.app' --args 1"
            }
            mapping {
                // (M)ission Control - All Apps
                fromKey = KeyCode.M
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'Mission Control.app' --args 3"
            }
            mapping {
                // N - App Expose
                fromKey = KeyCode.N
                fromModifiers = FromModifiers(mandatory = newCapsLockModifiers)
                shellCommand = "open -a 'Mission Control.app' --args 2"
            }
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

        // ring finger (w) sequences - #
        // ring finger (o) sequences - *
        karabinerRuleSingle {
            description = "J + W -> #"
            layerKey = KeyCode.J
            fromKey = KeyCode.W
            toKey = KeyCode.Num3
            toModifiers = listOf(LeftShift)
        },
        karabinerRuleSingle {
            description = "F + O -> *"
            layerKey = KeyCode.F
            fromKey = KeyCode.O
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

            //  P     L   ;
            //  =     /   - +
            mapping {
                fromKey = KeyCode.P
                toKey = KeyCode.EqualSign
            }

            mapping {
                fromKey = KeyCode.L
                toKey = KeyCode.Slash
            }
            mapping {
                fromKey = KeyCode.Semicolon
                toKey = KeyCode.Hyphen
            }
            mapping {
                fromKey = KeyCode.Quote
                toKey = KeyCode.EqualSign
                toModifiers = listOf(LeftShift)
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
                val fromModifierList =
                    newCapsLockModifiers + (modifiers ?: emptyList<ModifierKeyCode>())
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

fun openAllWindowsForApp(appName: String): String =
    "osascript -e 'tell application \"$appName\" to reopen' -e 'tell application \"$appName\" to activate'"

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
                fromModifiers =
                    FromModifiers(mandatory = listOf(LeftCommand) + newCapsLockModifiers)
                pointingButton = "button2"
            }
        }
    )

    return rules.toTypedArray()
}
