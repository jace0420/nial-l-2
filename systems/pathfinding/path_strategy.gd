## abstract base subclasses each encapsulate one routing behavior. adding one never changes WorldTravelSystem.
class_name PathStrategy extends RefCounted

enum PathMode {
	MANUAL,    ## straight line, ignores terrain (DirectPathStrategy)
	AUTOMATIC, ## least-cost route over terrain (TerrainAwarePathStrategy)
}

## optional one-time setup per map. no-op by default.
func prepare(_worldMap: WorldMap) -> void:
	pass

## returns inclusive tile list, or [] if no route. subclasses must override.
func findPath(_fromTile: Vector2i, _toTile: Vector2i, _worldMap: WorldMap) -> Array[Vector2i]:
	push_warning("PathStrategy.findPath called on the abstract base")
	return []
