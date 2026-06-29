class_name GridMovementComponent extends Node

const TILE_SIZE: int = 16
const MOVE_NORTH_ACTION: StringName = &"move_north"
const MOVE_SOUTH_ACTION: StringName = &"move_south"
const MOVE_WEST_ACTION: StringName = &"move_west"
const MOVE_EAST_ACTION: StringName = &"move_east"
const CHORD_WINDOW_SECONDS: float = 0.03

var _commitQueued: bool = false
var _waitingForNeutral: bool = false

## auto-disables on the world map; uses EventBus.mapChanged so nothing has to reach in to toggle it.
var _active: bool = true

func _ready() -> void:
	EventBus.mapChanged.connect(_onMapChanged)

func _onMapChanged(map: Node) -> void:
	_active = map is LocalMap

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_echo() or not _isMovementEvent(event):
		return
	if not event.is_pressed():
		_unlockIfNeutral()
		return
	if _waitingForNeutral or _commitQueued:
		return
	_commitQueued = true
	_commitMoveAfterChordWindow()

func _commitMoveAfterChordWindow() -> void:
	await get_tree().create_timer(CHORD_WINDOW_SECONDS).timeout
	_commitQueued = false
	if not _active:
		return
	var direction: Vector2i = _getHeldDirection()
	if direction == Vector2i.ZERO:
		_waitingForNeutral = _isAnyMovementPressed()
		return
	_waitingForNeutral = true
	var parent: Node2D = get_parent() as Node2D
	var from: Vector2 = parent.position
	if _isMovementBlocked(parent.global_position, direction):
		return
	parent.global_position = _moveOneTile(parent.global_position, direction)
	var to: Vector2 = parent.position
	EventBus.playerMoved.emit(from, to)

func _unlockIfNeutral() -> void:
	if _waitingForNeutral and not _isAnyMovementPressed():
		_waitingForNeutral = false

func _isMovementEvent(event: InputEvent) -> bool:
	if event.is_action(MOVE_NORTH_ACTION):
		return true
	if event.is_action(MOVE_SOUTH_ACTION):
		return true
	if event.is_action(MOVE_WEST_ACTION):
		return true
	if event.is_action(MOVE_EAST_ACTION):
		return true
	return false

func _getHeldDirection() -> Vector2i:
	var direction: Vector2i = Vector2i.ZERO
	if Input.is_action_pressed(MOVE_NORTH_ACTION):
		direction.y -= 1
	if Input.is_action_pressed(MOVE_SOUTH_ACTION):
		direction.y += 1
	if Input.is_action_pressed(MOVE_WEST_ACTION):
		direction.x -= 1
	if Input.is_action_pressed(MOVE_EAST_ACTION):
		direction.x += 1
	return direction

func _isAnyMovementPressed() -> bool:
	if Input.is_action_pressed(MOVE_NORTH_ACTION):
		return true
	if Input.is_action_pressed(MOVE_SOUTH_ACTION):
		return true
	if Input.is_action_pressed(MOVE_WEST_ACTION):
		return true
	if Input.is_action_pressed(MOVE_EAST_ACTION):
		return true
	return false

func _moveOneTile(fromPos: Vector2, direction: Vector2i) -> Vector2:
	var tileLayer: TileMapLayer = _getActiveTileLayer()
	if tileLayer != null:
		var fromTile: Vector2i = tileLayer.local_to_map(tileLayer.to_local(fromPos))
		var toTile: Vector2i = fromTile + direction
		return tileLayer.to_global(tileLayer.map_to_local(toTile))

	return fromPos + Vector2(direction) * TILE_SIZE

func _isMovementBlocked(fromPos: Vector2, direction: Vector2i) -> bool:
	var localMap: LocalMap = _getActiveLocalMap()
	if localMap == null:
		return false
	var tileLayer: TileMapLayer = localMap.getGroundLayer()
	if tileLayer == null:
		return false
	var fromTile: Vector2i = tileLayer.local_to_map(tileLayer.to_local(fromPos))
	var toTile: Vector2i = fromTile + direction
	if localMap.isObstacleTile(toTile):
		return true
	return localMap.getBlockingPropAt(toTile) != null

func _getActiveTileLayer() -> TileMapLayer:
	var mapManager: MapManager = _getMapManager()
	if mapManager == null or mapManager.currentMap == null:
		return null

	var localMap: LocalMap = mapManager.currentMap as LocalMap
	if localMap != null:
		return localMap.getGroundLayer()

	var worldMap: WorldMap = mapManager.currentMap as WorldMap
	if worldMap == null or worldMap.worldLayerPath.is_empty():
		return null
	return worldMap.get_node_or_null(worldMap.worldLayerPath) as TileMapLayer

func _getActiveLocalMap() -> LocalMap:
	var mapManager: MapManager = _getMapManager()
	if mapManager == null:
		return null
	return mapManager.currentMap as LocalMap

func _getMapManager() -> MapManager:
	var player: Node2D = get_parent() as Node2D
	if player == null:
		return null
	# Player lives inside SubViewport/SubViewportContainer walk up 3 levels to reach Game
	var gameRoot: Node = player.get_parent().get_parent().get_parent()
	if gameRoot == null:
		return null
	return gameRoot.get_node_or_null("MapManager") as MapManager
