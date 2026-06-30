## drives the inventory tabs. mirrors LogManager: it owns no inventory data, it only
## listens for EventBus.inventoryChanged and rebuilds one InventoryEntry per stack into
## the All tab plus the category tab matching the item's type. also routes the entries'
## button presses (equip/use/inspect/drop).
class_name InventoryUI extends Node

const ENTRY_SCENE: PackedScene = preload("res://ui/inventory_entry.tscn")
const ITEM_SCENE: PackedScene = preload("res://entities/item.tscn")

@export var allListPath: NodePath
@export var weaponsListPath: NodePath
@export var armorListPath: NodePath
@export var itemsListPath: NodePath

## needed so DROP can spawn a world item on the player's current tile.
@export var mapManagerPath: NodePath
@export var playerPath: NodePath

@onready var _allList: VBoxContainer = get_node(allListPath) as VBoxContainer
@onready var _weaponsList: VBoxContainer = get_node(weaponsListPath) as VBoxContainer
@onready var _armorList: VBoxContainer = get_node(armorListPath) as VBoxContainer
@onready var _itemsList: VBoxContainer = get_node(itemsListPath) as VBoxContainer
@onready var _mapManager: MapManager = get_node(mapManagerPath) as MapManager
@onready var _player: Node2D = get_node(playerPath) as Node2D


func _ready() -> void:
	EventBus.inventoryChanged.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	_clear(_allList)
	_clear(_weaponsList)
	_clear(_armorList)
	_clear(_itemsList)
	for stack: ItemStack in Inventory.getStacks():
		_allList.add_child(_makeEntry(stack))
		_categoryListFor(stack.item).add_child(_makeEntry(stack))


func _makeEntry(stack: ItemStack) -> InventoryEntry:
	var entry: InventoryEntry = ENTRY_SCENE.instantiate() as InventoryEntry
	entry.setup(stack)
	entry.equipPressed.connect(_onEquipPressed)
	entry.usePressed.connect(_onUsePressed)
	entry.inspectPressed.connect(_onInspectPressed)
	entry.dropPressed.connect(_onDropPressed)
	return entry


func _categoryListFor(item: Item) -> VBoxContainer:
	if item is Weapon:
		return _weaponsList
	if item is Armor:
		return _armorList
	return _itemsList


func _clear(list: VBoxContainer) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


# --- entry button handlers ---------------------------------------------------

func _onEquipPressed(item: Item) -> void:
	EventBus.logMessagePosted.emit("You equip the %s." % item.name, item.color)
	EventBus.itemEquipped.emit(item)


func _onUsePressed(item: Item) -> void:
	EventBus.logMessagePosted.emit("You use the %s." % item.name, item.color)
	EventBus.itemUsed.emit(item)


func _onInspectPressed(item: Item) -> void:
	var text: String = item.description if not item.description.is_empty() else item.shortDescription
	EventBus.logMessagePosted.emit(text, item.color)


func _onDropPressed(item: Item) -> void:
	Inventory.removeItem(item)
	_spawnWorldItem(item)
	EventBus.logMessagePosted.emit("You drop the %s." % item.name, item.color)


## drops a world pickup on the player's tile in the active local map. no-op on the
## world map (items only exist in close-range maps).
func _spawnWorldItem(item: Item) -> void:
	var localMap: LocalMap = _mapManager.currentMap as LocalMap
	if localMap == null:
		return
	var pickup: ItemPickup = ITEM_SCENE.instantiate() as ItemPickup
	pickup.item = item
	localMap.add_child(pickup)
	pickup.global_position = _player.global_position
