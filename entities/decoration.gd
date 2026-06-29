class_name Decoration extends Prop

@export var atlasRegion: Rect2 = Rect2(64, 64, 16, 16)
@export var description: String = ""
@export var messageColor: Color = Color.WHITE

@onready var _sprite: Sprite2D = $Sprite2D

var _atlasTexture: AtlasTexture = null

func _ready() -> void:
	var base: AtlasTexture = _sprite.texture as AtlasTexture
	if base != null:
		_atlasTexture = base.duplicate() as AtlasTexture
		_sprite.texture = _atlasTexture
		_atlasTexture.region = atlasRegion
	super._ready()

func interact(_actor: Node2D) -> bool:
	if description.is_empty():
		return false
	EventBus.logMessagePosted.emit(description, messageColor)
	return true
