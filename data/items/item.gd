extends Resource
class_name Item

# basically uses D&D 2014 rules

# META GAME
@export var canEquip: bool
@export var canUse: bool

# BASIC INFORMATION
@export var name: String
@export_multiline var description: String
@export_multiline var shortDescription: String
@export var color: Color
@export var properties = null #to be supplied

# SPECIFICS INFORMATION
@export var baseCost: int
# note on cost: we will handle everything in gold for the sake of simplicity, so no cp, sp, etc.
@export var baseWeight: int
@export var atlasTexture: AtlasTexture