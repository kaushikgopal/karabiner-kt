package sh.kau.karabiner

import kotlinx.serialization.json.JsonPrimitive
import sh.kau.karabiner.Condition.FrontmostApplicationIfCondition
import sh.kau.karabiner.Condition.FrontmostApplicationUnlessCondition
import sh.kau.karabiner.Condition.VariableIfCondition

typealias ShellCmd = String

// region Rule Datastructures
// -----------------------------------------
open class MappingRule(
    var fromKey: KeyCode? = null,
    var fromModifiers: FromModifiers? = null,
    var toKey: KeyCode? = null,
    var toKeys: List<KeyCode?>? = null,
    var toKeyIfAlone: KeyCode? = null,
    var toKeysIfAlone: List<KeyCode?>? = null,
    var shellCommand: ShellCmd? = null,
    var toModifiers: List<ModifierKeyCode?>? = null,
    var mouseKey: MouseKey? = null,
    var pointingButton: String? = null,
) {
  var conditions = mutableListOf<Condition>()

  fun forDevice(block: Condition.DeviceIfCondition.() -> Unit) {
    val cond = Condition.DeviceIfCondition()
    cond.block()
    conditions.add(cond)
  }

  fun forApp(block: FrontmostApplicationIfCondition.() -> Unit) {
    val cond = FrontmostApplicationIfCondition()
    cond.block()
    conditions.add(cond)
  }

  fun unlessApp(block: FrontmostApplicationUnlessCondition.() -> Unit) {
    val cond = FrontmostApplicationUnlessCondition()
    cond.block()
    conditions.add(cond)
  }
}

class SingleRule(
    var description: String = "",
    var layerKey: KeyCode? = null,
) : MappingRule()

/** Notice Layer Key Rule allows nested [mappings] whereas [SingleRule] allows just one mapping */
class LayerKeyRule(
    var description: String = "",
    var layerKey: KeyCode? = null,
) {
  internal var mappings = mutableListOf<MappingRule>()

  fun mapping(block: MappingRule.() -> Unit) {
    mappings.add(MappingRule().apply(block))
  }

  fun variableName() = "${layerKey!!.name.lowercase()}-layer"
}

// endregion

// region Karabiner Rule DSL
// --------------------------

@Deprecated("uses more complicated builder")
fun karabinerRule(description: String, vararg manipulators: Manipulator): KarabinerRule {
  return KarabinerRule(description, manipulators.toList())
}

/** Just allows for a nicer API (without mapping nesting) for Single Rules */
fun karabinerRuleSingle(
    block: SingleRule.() -> Unit,
): KarabinerRule {
  val singleRule = SingleRule().apply(block)
  return karabinerRule {
    description = singleRule.description
    layerKey = singleRule.layerKey
    mapping {
      fromKey = singleRule.fromKey
      fromModifiers = singleRule.fromModifiers
      toKey = singleRule.toKey
      toModifiers = singleRule.toModifiers
      toKeys = singleRule.toKeys
      toKeyIfAlone = singleRule.toKeyIfAlone
      toKeysIfAlone = singleRule.toKeysIfAlone
      shellCommand = singleRule.shellCommand
      mouseKey = singleRule.mouseKey
      pointingButton = singleRule.pointingButton
      conditions = singleRule.conditions
    }
  }
}

fun karabinerRule(
    block: LayerKeyRule.() -> Unit,
): KarabinerRule {
  val layerKeyRule = LayerKeyRule().apply(block)
  val manipulators = mutableListOf<Manipulator>()

  layerKeyRule.mappings.forEach { keyMapping ->
    val fromModifier =
        From.with(
            keyMapping.fromKey!!,
            keyMapping.fromModifiers,
        )

    val toModifier =
        if (keyMapping.toKeys != null && keyMapping.toKeys!!.isNotEmpty()) {
          // Build a sequence of To instructions, one for each key in toKeys
          keyMapping.toKeys!!.flatMap { singleToKey ->
            To.with(
                singleToKey,
                keyMapping.toModifiers,
            )
          }
        } else {
          To.with(
              keyMapping.toKey,
              keyMapping.toModifiers,
              keyMapping.shellCommand,
              keyMapping.mouseKey,
              keyMapping.pointingButton)
        }

    if (layerKeyRule.layerKey == null) {
      val toAloneModifier: List<To>? = when {
        keyMapping.toKeysIfAlone != null && keyMapping.toKeysIfAlone!!.isNotEmpty() ->
            keyMapping.toKeysIfAlone!!.flatMap { To.with(it) }
        keyMapping.toKeyIfAlone != null -> To.with(keyMapping.toKeyIfAlone)
        else -> null
      }

      manipulators +=
          Manipulator(
              from = fromModifier,
              to = toModifier,
              toIfAlone = toAloneModifier,
              conditions = if (keyMapping.conditions.isEmpty()) null else keyMapping.conditions,
          )
    } else {
      val variableName = layerKeyRule.variableName()
      // Layer Keys will need an onPress manipulator and an onRelease manipulator
      manipulators +=
          Manipulator(
              from = fromModifier,
              to = toModifier,
              conditions = ifVarSet(variableName) + keyMapping.conditions)

      manipulators +=
          Manipulator(
              from =
                  From(
                      simultaneous = listOf(layerKeyRule.layerKey!!, keyMapping.fromKey!!),
                      simultaneousOptions = buildSimultaneousOptionsVar(variableName),
                  ),
              to = setVarOn(toModifier, variableName),
              parameters = Parameters(simultaneousThresholdMilliseconds = 250),
              conditions = keyMapping.conditions)
    }
  }

  return KarabinerRule(layerKeyRule.description, manipulators)
}

// endregion

// region builder instructions
// ---------------------------

fun buildSimultaneousOptionsVar(variableName: String) =
    SimultaneousOptions(
        detectKeyDownUninterruptedly = true,
        keyDownOrder = "strict",
        keyUpOrder = "strict_inverse",
        keyUpWhen = "any",
        toAfterKeyUp = unsetVar(variableName),
    )

fun setVarOn(to: List<To>, variableName: String): List<To> =
    listOf(To(setVariable = SetVariable(variableName, JsonPrimitive(1)))) + to

fun unsetVar(variableName: String): List<To> =
    listOf(To(setVariable = SetVariable(variableName, JsonPrimitive(0))))

fun ifVarSet(variableName: String) = listOf(VariableIfCondition(variableName, JsonPrimitive(1)))

// endregion
