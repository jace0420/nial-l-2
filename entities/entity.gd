class_name Entity
extends Node2D

const TILE_SIZE: int = 16

func _ready() -> void:
	var localMap: LocalMap = _findLocalMapAncestor()
	if localMap != null:
		var layer: TileMapLayer = localMap.getGroundLayer()
		if layer != null:
			var tile: Vector2i = layer.local_to_map(layer.to_local(global_position))
			global_position = layer.to_global(layer.map_to_local(tile))
			return
	# No LocalMap ancesto fall back to raw tile snap so the entity still aligns.
	var halfTile: float = TILE_SIZE / 2.0
	global_position = (global_position / TILE_SIZE).floor() * TILE_SIZE + Vector2(halfTile, halfTile)

func getTile(tileLayer: TileMapLayer) -> Vector2i:
	if tileLayer == null:
		return Vector2i.ZERO
	return tileLayer.local_to_map(tileLayer.to_local(global_position))

func _findLocalMapAncestor() -> LocalMap:
	var node: Node = get_parent()
	while node != null:
		var localMap: LocalMap = node as LocalMap
		if localMap != null:
			return localMap
		node = node.get_parent()
	return null
