## local→world when the player steps off the edge; world→local via interact on a POI. both confirm first.
class_name MapTransitionSystem extends Node

const TILE_SIZE: int = 16

@export var mapManagerPath: NodePath
@export var playerPath: NodePath
@export var confirmationBoxPath: NodePath

enum TransferType { NONE, LOCAL_TO_WORLD, WORLD_TO_LOCAL }

## tracks where to return on the world map when the player exits the local map.
var _originPoi: WorldMapPoi = null
var _originWorldMapPath: String = ""

var _awaitingConfirmation: bool = false
var _pendingType: TransferType = TransferType.NONE
var _pendingScene: PackedScene = null
var _pendingSpawn: Vector2i = Vector2i.ZERO
var _pendingPoi: WorldMapPoi = null
var _pendingOriginWorldMapPath: String = ""

@onready var _mapManager: MapManager = get_node(mapManagerPath) as MapManager
@onready var _player: Node2D = get_node(playerPath) as Node2D
@onready var _confirmBox: ConfirmationUIBox = get_node(confirmationBoxPath) as ConfirmationUIBox

func _ready() -> void:
	EventBus.playerMoved.connect(_onPlayerMoved)
	_confirmBox.confirmed.connect(_onConfirmed)
	_confirmBox.cancelled.connect(_onCancelled)

func _unhandled_input(event: InputEvent) -> void:
	if _awaitingConfirmation:
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	var world: WorldMap = _mapManager.currentMap as WorldMap
	if world == null:
		return
	var poi: WorldMapPoi = world.getPoiAt(_playerTile())
	if poi == null or poi.localMapScene == null:
		return
	# Read defaultSpawn from a temporary instance so we don't hold a live node.
	var localInst: Node = poi.localMapScene.instantiate()
	var spawn: Vector2i = Vector2i.ZERO
	if localInst is LocalMap:
		spawn = (localInst as LocalMap).defaultSpawn
	localInst.free()
	_pendingType = TransferType.WORLD_TO_LOCAL
	_pendingScene = poi.localMapScene
	_pendingSpawn = spawn
	_pendingPoi = poi
	_pendingOriginWorldMapPath = world.scene_file_path
	_awaitingConfirmation = true
	var label: String = poi.displayName if not poi.displayName.is_empty() else "this area"
	_confirmBox.showBox("Enter " + label + "?")
	get_viewport().set_input_as_handled()

func _onPlayerMoved(from: Vector2, _to: Vector2) -> void:
	if _awaitingConfirmation:
		return
	var local: LocalMap = _mapManager.currentMap as LocalMap
	if local == null:
		return
	var tile: Vector2i = _playerTile()
	if local.isTilePainted(tile):
		return
	# Snap back to the last valid tile before showing the dialog.
	_player.position = from
	var worldScene: PackedScene = _resolveExitWorldScene()
	if worldScene == null:
		push_warning("MapTransitionSystem: no world map available to exit into")
		return
	var coords: Vector2i = _resolveExitCoords(worldScene, local)
	_pendingType = TransferType.LOCAL_TO_WORLD
	_pendingScene = worldScene
	_pendingSpawn = coords
	_awaitingConfirmation = true
	_confirmBox.showBox("Travel to the world map?")

func _onConfirmed() -> void:
	_awaitingConfirmation = false
	match _pendingType:
		TransferType.WORLD_TO_LOCAL:
			_originPoi = _pendingPoi
			_originWorldMapPath = _pendingOriginWorldMapPath
			_mapManager.changeMap(_pendingScene, _pendingSpawn)
		TransferType.LOCAL_TO_WORLD:
			_originPoi = null
			_originWorldMapPath = ""
			_mapManager.changeMap(_pendingScene, _pendingSpawn)
	_clearPending()

func _onCancelled() -> void:
	_awaitingConfirmation = false
	_clearPending()

func _clearPending() -> void:
	_pendingType = TransferType.NONE
	_pendingScene = null
	_pendingSpawn = Vector2i.ZERO
	_pendingPoi = null
	_pendingOriginWorldMapPath = ""

func _resolveExitWorldScene() -> PackedScene:
	if _originWorldMapPath != "":
		return load(_originWorldMapPath) as PackedScene
	return _mapManager.initialWorldMap

func _resolveExitCoords(worldScene: PackedScene, local: LocalMap) -> Vector2i:
	if _originPoi != null:
		return _originPoi.coordinates
	# Off-tree instantiation does not call _ready, so this is cheap.
	var temp: Node = worldScene.instantiate()
	var coords: Vector2i = Vector2i.ZERO
	if temp is WorldMap:
		var poi: WorldMapPoi = (temp as WorldMap).findPoiForLocalMap(local.scene_file_path)
		if poi != null:
			coords = poi.coordinates
	temp.free()
	return coords

func _playerTile() -> Vector2i:
	return Vector2i((_player.position / float(TILE_SIZE)).floor())
