## links a world-map tile to the local map it leads into.
class_name WorldMapPoi extends Resource

@export var coordinates: Vector2i = Vector2i.ZERO
@export var localMapScene: PackedScene
@export var displayName: String = ""
@export var markerTexture: Texture2D
@export var markerModulate: Color = Color.WHITE
