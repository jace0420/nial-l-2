## automatic mode: AStarGrid2D weighted by movementCost, deep water impassable.
class_name TerrainAwarePathStrategy extends PathStrategy

var _astar: AStarGrid2D = null
var _builtFor: WorldMap = null

## no-op if called again with the same map instance.
func prepare(worldMap: WorldMap) -> void:
	if worldMap == null:
		return
	if _astar != null and _builtFor == worldMap:
		return
	_builtFor = worldMap

	_astar = AStarGrid2D.new()
	_astar.region = worldMap.getUsedRect()
	_astar.cell_size = Vector2.ONE
	# Allow diagonal steps but don't let the path slip through a corner between
	# two solid (deep-water) tiles.
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	# Region/heuristics must be set before update(); solids and weights after.
	_astar.update()

	var rect: Rect2i = _astar.region
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var tile: Vector2i = Vector2i(x, y)
			if not worldMap.isPassable(tile):
				_astar.set_point_solid(tile, true)
			else:
				_astar.set_point_weight_scale(tile, float(worldMap.getMovementCost(tile)))

func findPath(fromTile: Vector2i, toTile: Vector2i, worldMap: WorldMap) -> Array[Vector2i]:
	prepare(worldMap)
	if _astar == null:
		return []
	if not _astar.is_in_boundsv(fromTile) or not _astar.is_in_boundsv(toTile):
		return []
	if _astar.is_point_solid(fromTile) or _astar.is_point_solid(toTile):
		return []
	return _astar.get_id_path(fromTile, toTile)
