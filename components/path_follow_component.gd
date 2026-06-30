## walks the player along a pre-resolved tile path; `stepped` is the world-travel tick all overworld systems hook onto.
class_name PathFollowComponent extends Node

const STEP_SECONDS_DEFAULT: float = 2.5

## emitted once per tile, before the icon commits to it.
signal stepped(tile: Vector2i)
## not emitted when stop() is called manually.
signal finished

var _worldMap: WorldMap = null
var _path: Array[Vector2i] = []
var _index: int = 0
var _timer: Timer = null

func _ready() -> void:
	EventBus.mapChanged.connect(_onMapChanged)
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = STEP_SECONDS_DEFAULT
	_timer.timeout.connect(_onStep)
	add_child(_timer)

func _onMapChanged(map: Node) -> void:
	_worldMap = map as WorldMap
	if _worldMap == null:
		stop()

## no-op if not on the world map or path has no movement.
func followPath(path: Array[Vector2i]) -> void:
	if _worldMap == null or _timer == null or path.size() <= 1:
		return
	_path = path
	_index = 1  # index 0 is where the player already stands
	_timer.start()

## safe to call before _ready (timer may not exist yet).
func stop() -> void:
	if _timer != null:
		_timer.stop()
	_path = []
	_index = 0

## freezes travel without losing the path (unlike stop()).
## TODO(overworld): wired via WorldTravelSystem._interruptTravel().
func pause() -> void:
	if _timer != null:
		_timer.paused = true

func resume() -> void:
	if _timer != null:
		_timer.paused = false

func setNextStepDuration(seconds: float) -> void:
	if _timer != null:
		_timer.wait_time = seconds

func _onStep() -> void:
	if _index >= _path.size():
		stop()
		finished.emit()
		return
	var parent: Node2D = get_parent() as Node2D
	if parent == null or _worldMap == null:
		stop()
		return
	var tile: Vector2i = _path[_index]
	# fires before the icon moves so consumers can react first.
	stepped.emit(tile)
	var from: Vector2 = parent.global_position
	var to: Vector2 = _worldMap.tileCenter(tile)
	parent.global_position = to
	EventBus.playerMoved.emit(from, to)
	_index += 1
	if _index >= _path.size():
		stop()
		finished.emit()
