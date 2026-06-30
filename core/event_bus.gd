extends Node

signal playerMoved(from: Vector2, to: Vector2)

## fires after the new map is active and the player repositioned.
signal mapChanged(map: Node)

signal diceRolled(result: DiceResult)

## world-travel lifecycle, emitted by WorldTravelSystem.
signal travelStarted(origin: Vector2i)
## reason is &"arrived" (route completed) or &"halted" (cancelled mid-route).
signal travelEnded(reason: StringName)

## a line to append to the game log. LogManager renders it; anyone may emit it.
signal logMessagePosted(text: String, color: Color)

## fires after the player's inventory changes (add/remove). InventoryUI rebuilds on this.
signal inventoryChanged

## fired when the player presses EQUIP/USE on an inventory entry. no effect yet —
## hooks for future equipment/consumable systems.
signal itemEquipped(item: Item)
signal itemUsed(item: Item)

