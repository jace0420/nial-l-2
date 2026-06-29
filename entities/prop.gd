class_name Prop extends Entity

@export var blocksMovement: bool = true
@export var interactionPriority: int = 0

@export var interactionOffsets: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]

func isMovementBlocked() -> bool:
	return blocksMovement

func canInteractFrom(actorTile: Vector2i, propTile: Vector2i) -> bool:
	for offset: Vector2i in interactionOffsets:
		if actorTile == propTile + offset:
			return true
	return false

# virtual; return true when the interaction was handled
func interact(_actor: Node2D) -> bool:
	return false
