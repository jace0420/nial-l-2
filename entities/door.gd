class_name Door extends Prop

@export var startsOpen: bool = false
@export var closedAtlasRegion: Rect2 = Rect2(192, 80, 16, 16)
@export var openAtlasRegion: Rect2 = Rect2(0, 0, 16, 16)

signal stateChanged(door: Door, isOpen: bool)

var isOpen: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

# Duplicated atlas texture so each door instance has its own sub-resource.
var _atlasTexture: AtlasTexture = null

func _ready() -> void:
	isOpen = startsOpen
	blocksMovement = not isOpen
	var base: AtlasTexture = _sprite.texture as AtlasTexture
	if base != null:
		_atlasTexture = base.duplicate() as AtlasTexture
		_sprite.texture = _atlasTexture
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
	if _atlasTexture == null:
		return
	_atlasTexture.region = openAtlasRegion if isOpen else closedAtlasRegion
