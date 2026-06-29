extends Node

signal playerMoved(from: Vector2, to: Vector2)

## fires after the new map is active and the player repositioned.
signal mapChanged(map: Node)

signal diceRolled(result: DiceResult)

