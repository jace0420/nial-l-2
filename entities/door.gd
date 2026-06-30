class_name Door extends Prop

@export var startsOpen: bool = false
@export var closedAtlasTexture: AtlasTexture
@export var openAtlasTexture: AtlasTexture

signal stateChanged(door: Door, isOpen: bool)

var isOpen: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	interactionPriority = 10
	isOpen = startsOpen
	blocksMovement = not isOpen
	super._ready()
	_updateVisual()

func isMovementBlocked() -> bool:
	return not isOpen

func interact(actor: Node2D) -> bool:
	if isOpen:
		var localMap: LocalMap = _findLocalMapAncestor()
		if localMap != null:
			if localMap.getTileForNode(actor) == localMap.getTileForNode(self):
				return false

	isOpen = not isOpen
	blocksMovement = not isOpen
	_updateVisual()
	stateChanged.emit(self, isOpen)
	return true

func _updateVisual() -> void:
	var tex: AtlasTexture = openAtlasTexture if isOpen else closedAtlasTexture
	if tex != null:
		_sprite.texture = tex
