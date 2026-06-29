## owns the active map, swaps it on demand. player persists across swaps MapManager repositions it.
class_name MapManager extends Node

const TILE_SIZE: int = 16

@export var initialMap: PackedScene

## fallback world map when no recorded origin exists (e.g. fresh start in a local map).
@export var initialWorldMap: PackedScene

@export var playerPath: NodePath

## should be the SubViewport so maps render alongside the Player.
@export var mapParentPath: NodePath

var currentMap: Node = null

func _ready() -> void:
	if initialMap == null:
		push_warning("MapManager: initialMap is not set")
		return
	var spawn: Vector2i = Vector2i.ZERO
	var inst: Node = initialMap.instantiate()
	if inst is LocalMap:
		spawn = (inst as LocalMap).defaultSpawn
	changeMapInstance(inst, spawn)

func changeMap(scene: PackedScene, spawnTile: Vector2i) -> void:
	if scene == null:
		push_warning("MapManager.changeMap: null scene")
		return
	changeMapInstance(scene.instantiate(), spawnTile)

## takes a pre-built node instead of a PackedScene.
func changeMapInstance(mapInstance: Node, spawnTile: Vector2i) -> void:
	if currentMap != null:
		currentMap.queue_free()
		currentMap = null
	var parent: Node = _getMapParent()
	parent.add_child(mapInstance)
	currentMap = mapInstance
	_placePlayer(spawnTile)
	EventBus.mapChanged.emit(mapInstance)

func _placePlayer(spawnTile: Vector2i) -> void:
	var player: Node2D = _getPlayer()
	if player == null:
		return
	var halfTile: float = TILE_SIZE / 2.0
	player.position = Vector2(
		spawnTile.x * TILE_SIZE + halfTile,
		spawnTile.y * TILE_SIZE + halfTile
	)

func _getPlayer() -> Node2D:
	if playerPath.is_empty():
		return null
	return get_node(playerPath) as Node2D

func _getMapParent() -> Node:
	if not mapParentPath.is_empty():
		var n: Node = get_node_or_null(mapParentPath)
		if n != null:
			return n
	push_warning("MapManager: mapParentPath not set or invalid, adding map to MapManager itself")
	return self
