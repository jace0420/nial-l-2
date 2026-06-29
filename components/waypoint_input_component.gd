## inside the SubViewport so get_global_mouse_position() accounts for Camera2D automatically.
class_name WaypointInputComponent extends Node

signal tileDoubleClicked(tile: Vector2i)

## null on local maps guard condition.
var _worldMap: WorldMap = null

func _ready() -> void:
	EventBus.mapChanged.connect(_onMapChanged)

func _onMapChanged(map: Node) -> void:
	_worldMap = map as WorldMap

func _unhandled_input(event: InputEvent) -> void:
	if _worldMap == null:
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.double_click:
		return
	var parent: Node2D = get_parent() as Node2D
	if parent == null:
		return
	var tile: Vector2i = _worldMap.worldToTile(parent.get_global_mouse_position())
	if not _worldMap.isTilePainted(tile):
		return
	tileDoubleClicked.emit(tile)
	get_viewport().set_input_as_handled()
