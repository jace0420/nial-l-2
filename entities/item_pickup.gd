## an Item lying in the world that the player can walk up to and pick up with E.
## drives its own sprite from the assigned Item resource, so a designer only needs
## to drop this scene into a map and assign a .tres in the inspector.
class_name ItemPickup extends Prop

@export var item: Item

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if item != null:
		if item.atlasTexture != null:
			_sprite.texture = item.atlasTexture
		_sprite.modulate = item.color
	super._ready()


func interact(_actor: Node2D) -> bool:
	if item == null:
		return false
	Inventory.addItem(item)
	EventBus.logMessagePosted.emit("You pick up the %s." % item.name, item.color)
	queue_free()
	return true
