extends InteractableUI
class_name AbilityHudElement

## An [InteractableUI] slot that represents one ability in the player's inventory.
##
## [param slot] maps directly to an index in [AbilityManager.abilities].
## The icon texture is driven externally: [UIController] listens to
## [signal AbilityManager.ability_registered] / [signal AbilityManager.ability_unregistered]
## and calls [method UIHUD.update_ability_icon], which sets [member ability_icon]'s texture.
##
## This element does not hold a reference to the [Ability] itself — the manager
## is the single source of truth for what lives in each slot.
 
## Which slot in [AbilityManager.abilities] this element represents (0–3).
@export var slot: int
 
## The [Sprite2D] that displays the ability icon. Kept as a public export so
## [UIHUD] can reference it directly via its ability_icons array if needed.
@export var ability_icon: Sprite2D


func select(hand: UIHand) -> void:
	hand.selected_element = self
	if hand.current_state != UIHand.State.HOLDING:
		hand.change_state(UIHand.State.HOVER_OVER_ACTIVATEABLE)


func deselect(hand: UIHand) -> void:
	pass
 
func activate(hand: UIHand) -> void:
	
	if hand.current_state != UIHand.State.HOLDING:
		# Nothing held yet — pick up this slot's ability.
		hand.grab_ability_from(self)
	else:
		# Already holding — drop onto this slot (swap or move).
		hand.drop_ability_onto(self)
