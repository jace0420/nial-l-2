## wide-scope map (mile tiles). POIs link tiles to local maps; markers spawn at runtime.
class_name WorldMap extends Node2D

const TILE_SIZE: int = 16

## transfer points to local maps, editable in the inspector.
@export var pois: Array[WorldMapPoi] = []

@export var worldLayerPath: NodePath = ^"WorldTileMapLayer"

var _poiByCoord: Dictionary = {} # Vector2i -> WorldMapPoi
var _markersRoot: Node2D

func _ready() -> void:
	_markersRoot = Node2D.new()
	_markersRoot.name = "Markers"
	add_child(_markersRoot)
	_buildPoiIndex()
	_spawnMarkers()
	# TODO(overworld): add a runtime-spawned "WorldActors" Node2D container here
	# (mirroring _markersRoot) to hold NPC/enemy overworld entities. A future
	# WorldActorSystem will step them on PathFollowComponent.stepped so they move
	# in lockstep with the player's travel and are visible along the route.

func _buildPoiIndex() -> void:
	_poiByCoord.clear()
	for poi: WorldMapPoi in pois:
		if poi == null:
			continue
		_poiByCoord[poi.coordinates] = poi

func _spawnMarkers() -> void:
	var halfTile: float = TILE_SIZE / 2.0
	for poi: WorldMapPoi in pois:
		if poi == null or poi.markerTexture == null:
			continue
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = poi.markerTexture
		sprite.modulate = poi.markerModulate
		sprite.position = Vector2(
			poi.coordinates.x * TILE_SIZE + halfTile,
			poi.coordinates.y * TILE_SIZE + halfTile
		)
		sprite.z_index = 1
		_markersRoot.add_child(sprite)

## high enough that the pathfinder always prefers any real (painted) tile.
const UNPAINTED_MOVEMENT_COST: int = 99

const TERRAIN_TYPE_KEY: StringName = &"terrainType"
const MOVEMENT_COST_KEY: StringName = &"movementCost"

func getWorldLayer() -> TileMapLayer:
	if worldLayerPath.is_empty():
		return null
	return get_node_or_null(worldLayerPath) as TileMapLayer

func worldToTile(globalPos: Vector2) -> Vector2i:
	var layer: TileMapLayer = getWorldLayer()
	if layer == null:
		return Vector2i.ZERO
	return layer.local_to_map(layer.to_local(globalPos))

func tileCenter(tile: Vector2i) -> Vector2:
	var layer: TileMapLayer = getWorldLayer()
	if layer == null:
		return Vector2.ZERO
	return layer.to_global(layer.map_to_local(tile))

## empty cell = off-map.
func isTilePainted(tile: Vector2i) -> bool:
	var layer: TileMapLayer = getWorldLayer()
	if layer == null:
		return false
	return layer.get_cell_source_id(tile) != -1

func getTerrainType(tile: Vector2i) -> String:
	var data: TileData = _getTileData(tile)
	if data == null:
		return ""
	return data.get_custom_data(TERRAIN_TYPE_KEY)

func getMovementCost(tile: Vector2i) -> int:
	var data: TileData = _getTileData(tile)
	if data == null:
		return UNPAINTED_MOVEMENT_COST
	return int(data.get_custom_data(MOVEMENT_COST_KEY))

## only deep water is impassable; everything else painted is walkable.
func isPassable(tile: Vector2i) -> bool:
	return isTilePainted(tile) and getTerrainType(tile) != "deepWater"

func getUsedRect() -> Rect2i:
	var layer: TileMapLayer = getWorldLayer()
	if layer == null:
		return Rect2i()
	return layer.get_used_rect()

func _getTileData(tile: Vector2i) -> TileData:
	var layer: TileMapLayer = getWorldLayer()
	if layer == null:
		return null
	return layer.get_cell_tile_data(tile)

func getPoiAt(tile: Vector2i) -> WorldMapPoi:
	return _poiByCoord.get(tile, null) as WorldMapPoi

## compares by resource_path so it works even off-tree.
func findPoiForLocalMap(localScenePath: String) -> WorldMapPoi:
	for poi: WorldMapPoi in pois:
		if poi == null or poi.localMapScene == null:
			continue
		if poi.localMapScene.resource_path == localScenePath:
			return poi
	return null
