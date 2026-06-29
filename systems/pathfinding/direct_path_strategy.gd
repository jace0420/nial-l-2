## manual mode: Bresenham straight line, ignores terrain.
class_name DirectPathStrategy extends PathStrategy

func findPath(fromTile: Vector2i, toTile: Vector2i, _worldMap: WorldMap) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0: int = fromTile.x
	var y0: int = fromTile.y
	var x1: int = toTile.x
	var y1: int = toTile.y
	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return points
