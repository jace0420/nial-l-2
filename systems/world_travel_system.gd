## coordinates overworld travel: waypoint placement, pathfinding, confirmation, then walking. owns no algorithm itself.
class_name WorldTravelSystem extends Node

const CONFIRM_ACTION: StringName = &"travel_confirm"
const CANCEL_ACTION: StringName = &"travel_cancel"
const MODE_TOGGLE_ACTION: StringName = &"travel_mode_toggle"
const UNDO_ACTION: StringName = &"travel_undo_waypoint"

const HINT: String = "Dbl-click: waypoint   Enter: travel   Esc: clear   Tab: mode   Bksp: undo"

enum State {
	IDLE,        ## not on the world map; system dormant
	PLANNING,    ## placing waypoints
	CONFIRMING,  ## "Begin travel?" dialog is open
	TRAVELING,   ## icon auto-walking the route
	INTERRUPTED, ## travel frozen mid-route (reserved for future encounters)
}

@export var mapManagerPath: NodePath
@export var playerPath: NodePath
@export var waypointInputPath: NodePath
@export var pathFollowPath: NodePath
@export var rendererPath: NodePath
@export var confirmBoxPath: NodePath
@export var statusLabelPath: NodePath

@onready var _mapManager: MapManager = get_node(mapManagerPath) as MapManager
@onready var _player: Node2D = get_node(playerPath) as Node2D
@onready var _waypointInput: WaypointInputComponent = get_node(waypointInputPath) as WaypointInputComponent
@onready var _pathFollow: PathFollowComponent = get_node(pathFollowPath) as PathFollowComponent
@onready var _renderer: TravelPathRenderer = get_node(rendererPath) as TravelPathRenderer
@onready var _confirmBox: ConfirmationUIBox = get_node(confirmBoxPath) as ConfirmationUIBox
@onready var _statusLabel: Label = get_node(statusLabelPath) as Label

var _directStrategy: DirectPathStrategy = DirectPathStrategy.new()
var _terrainStrategy: TerrainAwarePathStrategy = TerrainAwarePathStrategy.new()

var _state: State = State.IDLE
var _mode: PathStrategy.PathMode = PathStrategy.PathMode.AUTOMATIC
var _route: TravelRoute = TravelRoute.new()
var _worldMap: WorldMap = null
var _resolveFailed: bool = false

func _ready() -> void:
	EventBus.mapChanged.connect(_onMapChanged)
	_waypointInput.tileDoubleClicked.connect(_onTileDoubleClicked)
	_pathFollow.finished.connect(_onTravelFinished)
	_confirmBox.confirmed.connect(_onConfirmed)
	_confirmBox.cancelled.connect(_onCancelled)
	# deferred so PathFollowComponent finishes _ready before we touch it.
	_onMapChanged.call_deferred(_mapManager.currentMap)

func _onMapChanged(map: Node) -> void:
	_worldMap = map as WorldMap
	if _worldMap != null:
		WorldTime.setPaused(true)
		_terrainStrategy.prepare(_worldMap)
		_resetRoute()
		_setState(State.PLANNING)
	else:
		WorldTime.setPaused(false)
		_pathFollow.stop()
		_renderer.clear()
		_setState(State.IDLE)

func _unhandled_input(event: InputEvent) -> void:
	# Dormant off the world map; the dialog owns input while confirming.
	if _state == State.IDLE or _state == State.CONFIRMING:
		return
	if event.is_action_pressed(CONFIRM_ACTION):
		_requestConfirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(CANCEL_ACTION):
		_cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(MODE_TOGGLE_ACTION):
		_toggleMode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(UNDO_ACTION):
		_undoWaypoint()
		get_viewport().set_input_as_handled()

func _onTileDoubleClicked(tile: Vector2i) -> void:
	if _state != State.PLANNING:
		return
	_route.addWaypoint(tile)
	_resolveAndRefresh()

func _toggleMode() -> void:
	if _state != State.PLANNING:
		return
	_mode = PathStrategy.PathMode.MANUAL if _mode == PathStrategy.PathMode.AUTOMATIC \
		else PathStrategy.PathMode.AUTOMATIC
	_resolveAndRefresh()

func _undoWaypoint() -> void:
	if _state != State.PLANNING:
		return
	_route.removeLastWaypoint()
	_resolveAndRefresh()

func _cancel() -> void:
	match _state:
		State.PLANNING:
			_resetRoute()
			_resolveAndRefresh()
		State.TRAVELING:
			_pathFollow.stop()
			_resetRoute()
			_setState(State.PLANNING)
			_resolveAndRefresh()

func _requestConfirm() -> void:
	if _state != State.PLANNING or not _route.hasPath():
		return
	_setState(State.CONFIRMING)
	_confirmBox.showBox("Begin travel?")

func _onConfirmed() -> void:
	if _state != State.CONFIRMING:
		return
	_setState(State.TRAVELING)
	_pathFollow.followPath(_route.path)

func _onCancelled() -> void:
	if _state != State.CONFIRMING:
		return
	_setState(State.PLANNING)  # route stays intact for further editing

func _onTravelFinished() -> void:
	_renderer.clear()
	_resetRoute()
	_setState(State.PLANNING)
	_resolveAndRefresh()

# TODO(overworld): encounter seam not wired yet

## freezes the route mid-travel for a future EncounterSystem. resolve with _resumeTravel().
func _interruptTravel(_reason: StringName) -> void:
	if _state != State.TRAVELING:
		return
	_pathFollow.pause()
	_setState(State.INTERRUPTED)

func _resumeTravel() -> void:
	if _state != State.INTERRUPTED:
		return
	_setState(State.TRAVELING)
	_pathFollow.resume()

func _resetRoute() -> void:
	if _worldMap == null:
		return
	_route.reset(_worldMap.worldToTile(_player.global_position))
	_resolveFailed = false

## rebuilds the full tile path; a blocked segment marks the whole route unresolved.
func _resolvePath() -> void:
	var waypoints: Array[Vector2i] = _route.waypoints
	if waypoints.is_empty():
		_route.path = []
		return
	var full: Array[Vector2i] = []
	full.append(waypoints[0])
	var strategy: PathStrategy = _activeStrategy()
	for i: int in range(waypoints.size() - 1):
		var segment: Array[Vector2i] = strategy.findPath(waypoints[i], waypoints[i + 1], _worldMap)
		if segment.is_empty():
			_route.path = []
			_resolveFailed = true
			return
		# Each segment includes both endpoints; drop the first to avoid
		# duplicating the tile shared with the previous segment.
		for j: int in range(1, segment.size()):
			full.append(segment[j])
	_route.path = full
	_resolveFailed = false

func _resolveAndRefresh() -> void:
	_resolvePath()
	_renderer.showRoute(_route, _mode)
	_updateStatus()

func _activeStrategy() -> PathStrategy:
	if _mode == PathStrategy.PathMode.MANUAL:
		return _directStrategy
	return _terrainStrategy

func _setState(newState: State) -> void:
	_state = newState
	_statusLabel.visible = newState != State.IDLE
	_updateStatus()

func _updateStatus() -> void:
	if not _statusLabel.visible:
		return
	var modeName: String = "MANUAL" if _mode == PathStrategy.PathMode.MANUAL else "AUTOMATIC"
	match _state:
		State.TRAVELING:
			_statusLabel.text = "Traveling…   Esc: stop"
		State.INTERRUPTED:
			_statusLabel.text = "Travel interrupted."
		_:
			if _resolveFailed:
				_statusLabel.text = "%s | No path found (deep water blocks the route).   %s" % [modeName, HINT]
			else:
				_statusLabel.text = "%s | %s" % [modeName, HINT]
