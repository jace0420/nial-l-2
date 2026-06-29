## close-range map (5ft tiles). any unpainted ground tile is a boundary to the world map.
class_name LocalMap extends Node2D

const TILE_SIZE: int = 16

## player snaps here when entering from the world map.
@export var defaultSpawn: Vector2i = Vector2i.ZERO

@export var groundLayerPath: NodePath = ^"GroundTileMapLayer"
@export var obstaclesLayerPath: NodePath = ^"ObstaclesTileMapLayer"

func getGroundLayer() -> TileMapLayer:
	return get_node(groundLayerPath) as TileMapLayer

func getObstaclesLayer() -> TileMapLayer:
	return get_node_or_null(obstaclesLayerPath) as TileMapLayer

## empty cell (source_id == -1) counts as a map boundary.
func isTilePainted(tile: Vector2i) -> bool:
	var layer: TileMapLayer = getGroundLayer()
	if layer == null:
		return false
	return layer.get_cell_source_id(tile) != -1

func isObstacleTile(tile: Vector2i) -> bool:
	var layer: TileMapLayer = getObstaclesLayer()
	if layer == null:
		return false
	return layer.get_cell_source_id(tile) != -1

func getBlockingPropAt(tile: Vector2i) -> Prop:
	var layer: TileMapLayer = getGroundLayer()
	if layer == null:
		return null
	for child: Node in get_children():
		var prop: Prop = child as Prop
		if prop == null or not prop.isMovementBlocked():
			continue
		var propTile: Vector2i = layer.local_to_map(layer.to_local(prop.global_position))
		if propTile == tile:
			return prop
	return null

func getTileForNode(node: Node2D) -> Vector2i:
	var layer: TileMapLayer = getGroundLayer()
	if layer == null:
		return Vector2i.ZERO
	return layer.local_to_map(layer.to_local(node.global_position))

func getInteractablePropsNear(tile: Vector2i) -> Array[Prop]:
	var layer: TileMapLayer = getGroundLayer()
	var result: Array[Prop] = []
	if layer == null:
		return result
	for child: Node in get_children():
		var prop: Prop = child as Prop
		if prop == null:
			continue
		var propTile: Vector2i = layer.local_to_map(layer.to_local(prop.global_position))
		if prop.canInteractFrom(tile, propTile):
			result.append(prop)
	return result
