## planned overworld journey WorldTravelSystem fills this in TravelPathRenderer reads it.
class_name TravelRoute extends RefCounted

## index 0 is always the travel origin.
var waypoints: Array[Vector2i] = []

## full tile path, inclusive of origin and destination.
var path: Array[Vector2i] = []

func reset(origin: Vector2i) -> void:
	waypoints = [origin]
	path = [origin]

## path resolution is the caller's job.
func addWaypoint(tile: Vector2i) -> void:
	waypoints.append(tile)

## never removes the origin at index 0.
func removeLastWaypoint() -> void:
	if waypoints.size() > 1:
		waypoints.remove_at(waypoints.size() - 1)

func isEmpty() -> bool:
	return waypoints.size() <= 1

func hasPath() -> bool:
	return path.size() > 1
