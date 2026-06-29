## pure view: renders the planned route. WorldTravelSystem pushes data via showRoute(); this node just draws.
class_name TravelPathRenderer extends Node2D

const TILE_SIZE: int = 16
const PATH_WIDTH: float = 2.0
const PATH_SHADOW_WIDTH: float = 4.0
const WAYPOINT_RADIUS: float = 4.0
const DESTINATION_RADIUS: float = 5.5

const COLOR_AUTOMATIC: Color = Color(0.3, 0.9, 0.4, 0.95)  # green: terrain-aware
const COLOR_MANUAL: Color = Color(1.0, 0.7, 0.2, 0.95)     # amber: straight line
const COLOR_WAYPOINT: Color = Color(1.0, 1.0, 1.0, 1.0)

## shadow underlay for contrast over busy terrain.
const COLOR_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.45)
## Alpha for the faint outline drawn around each waypoint's tile.
const TILE_OUTLINE_ALPHA: float = 0.30

var _worldMap: WorldMap = null
var _path: Array[Vector2i] = []
var _waypoints: Array[Vector2i] = []
var _lineColor: Color = COLOR_AUTOMATIC

func _ready() -> void:
	EventBus.mapChanged.connect(_onMapChanged)

func _onMapChanged(map: Node) -> void:
	_worldMap = map as WorldMap
	clear()

## mode only affects the line color.
func showRoute(route: TravelRoute, mode: PathStrategy.PathMode) -> void:
	_path = route.path
	_waypoints = route.waypoints
	_lineColor = COLOR_MANUAL if mode == PathStrategy.PathMode.MANUAL else COLOR_AUTOMATIC
	queue_redraw()

func clear() -> void:
	_path = []
	_waypoints = []
	queue_redraw()

func _draw() -> void:
	if _worldMap == null:
		return
	_drawPath()
	# skip index 0 (origin where the player already stands).
	for i: int in range(1, _waypoints.size()):
		var center: Vector2 = to_local(_worldMap.tileCenter(_waypoints[i]))
		var isDestination: bool = i == _waypoints.size() - 1
		_drawWaypoint(center, isDestination)

func _drawPath() -> void:
	if _path.size() < 2:
		return
	var points: PackedVector2Array = PackedVector2Array()
	for tile: Vector2i in _path:
		points.append(to_local(_worldMap.tileCenter(tile)))
	draw_polyline(points, COLOR_SHADOW, PATH_SHADOW_WIDTH, true)
	draw_polyline(points, _lineColor, PATH_WIDTH, true)

func _drawWaypoint(center: Vector2, isDestination: bool) -> void:
	var tile: float = float(TILE_SIZE)
	var cell: Rect2 = Rect2(center - Vector2(tile, tile) * 0.5, Vector2(tile, tile))
	draw_rect(cell, Color(_lineColor, TILE_OUTLINE_ALPHA), false, 1.0)
	var radius: float = DESTINATION_RADIUS if isDestination else WAYPOINT_RADIUS
	draw_arc(center, radius, 0.0, TAU, 24, COLOR_SHADOW, 2.0, true)
	draw_circle(center, radius - 1.0, COLOR_WAYPOINT)
