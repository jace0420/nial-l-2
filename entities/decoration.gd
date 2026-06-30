class_name Decoration extends Prop

@export var atlasTexture: AtlasTexture
@export var description: String = ""
@export var messageColor: Color = Color.WHITE

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if atlasTexture != null:
		_sprite.texture = atlasTexture
	super._ready()

func interact(_actor: Node2D) -> bool:
	if description.is_empty():
		return false
	EventBus.logMessagePosted.emit(description, messageColor)
	return true
