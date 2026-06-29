class_name InteractionSystem extends Node

const INTERACT_ACTION: StringName = &"interact"

@export var mapManagerPath: NodePath
@export var playerPath: NodePath

@onready var _mapManager: MapManager = get_node(mapManagerPath) as MapManager
@onready var _player: Node2D = get_node(playerPath) as Node2D

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(INTERACT_ACTION) or event.is_echo():
		return
	# Only handle local map props. World map transitions fall through to MapTransitionSystem.
	var localMap: LocalMap = _mapManager.currentMap as LocalMap
	if localMap == null:
		return
	var playerTile: Vector2i = localMap.getTileForNode(_player)
	for prop: Prop in localMap.getInteractablePropsNear(playerTile):
		if prop.interact(_player):
			get_viewport().set_input_as_handled()
			return
