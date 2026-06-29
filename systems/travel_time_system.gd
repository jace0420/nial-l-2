## turns each world-travel tick into elapsed in-game time and narrates the journey to the log.
## time is rolled per tile (d20), scaled by the tile's movementCost and whether the step is diagonal.
class_name TravelTimeSystem extends Node

## minutes to cross one 2-mile road tile (movementCost 1) on a nat-20 (fast) and a nat-1 (slow).
@export var fastMinutes: int = 30
@export var slowMinutes: int = 60
## diagonal steps cover ~2.83 miles instead of 2; set to 1.0 to make every tile cost the same.
@export var diagonalFactor: float = 1.4142
@export var pathFollowPath: NodePath

const MILES_PER_TILE: float = 2.0

const COLOR_TRAVEL: Color = Color("008000")   ## set out / neutral travel info
const COLOR_GOOD: Color   = Color("00ff00")   ## made great time (nat 20)
const COLOR_BAD: Color    = Color("ff0000")   ## slow going (nat 1)
const COLOR_TIME: Color   = Color("00ffff")   ## a new day dawns mid-journey
const COLOR_ARRIVE: Color = Color("ffff00")   ## arrival summary
const COLOR_HALT: Color   = Color("808080")   ## travel halted

@onready var _pathFollow: PathFollowComponent = get_node(pathFollowPath) as PathFollowComponent

var _dice: DiceManager = DiceManager.new()
var _worldMap: WorldMap = null

var _active: bool = false
var _previousTile: Vector2i = Vector2i.ZERO
var _totalMinutes: int = 0
var _miles: float = 0.0
var _tileCount: int = 0
var _terrainMinutes: Dictionary = {} # terrainType: String -> minutes: int


func _ready() -> void:
	add_child(_dice)
	EventBus.mapChanged.connect(_onMapChanged)
	EventBus.travelStarted.connect(_onTravelStarted)
	EventBus.travelEnded.connect(_onTravelEnded)
	WorldTime.dayChanged.connect(_onDayChanged)
	_pathFollow.stepped.connect(_onStepped)


func _onMapChanged(map: Node) -> void:
	_worldMap = map as WorldMap
	if _worldMap == null:
		_active = false


func _onTravelStarted(origin: Vector2i) -> void:
	_active = true
	_previousTile = origin
	_totalMinutes = 0
	_miles = 0.0
	_tileCount = 0
	_terrainMinutes.clear()
	_post("You set out to travel your route.", COLOR_TRAVEL)


## fires once per tile, before the icon commits to it (see PathFollowComponent).
func _onStepped(tile: Vector2i) -> void:
	if not _active or _worldMap == null:
		return
	var direction: Vector2i = tile - _previousTile
	var diagonal: bool = direction.x != 0 and direction.y != 0
	var cost: int = _worldMap.getMovementCost(tile)
	var terrain: String = _worldMap.getTerrainType(tile)

	var result: DiceResult = _dice.roll(DiceManager.Die.D20)
	var roll: int = result.rolls[0]
	var base: float = float(slowMinutes) - float(roll - 1) * float(slowMinutes - fastMinutes) / 19.0
	var factor: float = diagonalFactor if diagonal else 1.0
	var minutes: int = int(round(base * float(cost) * factor))

	WorldTime.advanceMinutes(minutes)

	_totalMinutes += minutes
	_miles += MILES_PER_TILE * (diagonalFactor if diagonal else 1.0)
	_tileCount += 1
	_terrainMinutes[terrain] = int(_terrainMinutes.get(terrain, 0)) + minutes
	_previousTile = tile

	# hybrid logging: only the standout tiles get their own line.
	if result.is_critical:
		_post("You move quickly across the %s in %s." % [_terrainName(terrain), _formatDuration(minutes)], COLOR_GOOD)
	elif result.is_fumble:
		_post("You move slow across the %s in %s." % [_terrainName(terrain), _formatDuration(minutes)], COLOR_BAD)


func _onDayChanged(_day: int, _month: int, _year: int) -> void:
	if not _active:
		return
	_post("A new day begins on your travel: %s." % WorldTime.getDateString(), COLOR_TIME)


func _onTravelEnded(reason: StringName) -> void:
	if not _active:
		return
	_active = false
	if _tileCount == 0:
		return
	var miles: String = _formatMiles(_miles)
	var duration: String = _formatDuration(_totalMinutes)
	var terrain: String = _terrainSummary()
	if reason == &"halted":
		_post("You halt after %s of travel (%s through %s). It is now %s, %s." \
			% [miles, duration, terrain, WorldTime.getTimeString(), WorldTime.getDateString()], COLOR_HALT)
	else:
		_post("Arrived after %s of travel (%s through %s). It is now %s, %s." \
			% [miles, duration, terrain, WorldTime.getTimeString(), WorldTime.getDateString()], COLOR_ARRIVE)


func _post(text: String, color: Color) -> void:
	EventBus.logMessagePosted.emit(text, color)


## "Xh Ym", or "Ym" under an hour.
func _formatDuration(minutes: int) -> String:
	var hours: int = minutes / 60
	var mins: int = minutes % 60
	if hours <= 0:
		return "%dm" % mins
	if mins == 0:
		return "%dh" % hours
	return "%dh %dm" % [hours, mins]


func _formatMiles(miles: float) -> String:
	return "%d miles" % int(round(miles))


## human-readable terrain label; falls back to "wilds" for unpainted/blank terrain.
func _terrainName(terrain: String) -> String:
	if terrain.is_empty():
		return "wilds"
	return terrain


## the distinct terrain types crossed, in the order they were first encountered.
func _terrainSummary() -> String:
	var names: Array[String] = []
	for terrain: String in _terrainMinutes.keys():
		names.append(_terrainName(terrain))
	if names.is_empty():
		return "open country"
	return ", ".join(names)
