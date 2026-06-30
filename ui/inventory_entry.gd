## one row in the inventory list. populates its labels from an ItemStack and shows the
## EQUIP/USE buttons only when the item allows it (canEquip / canUse). owns no inventory
## logic — it re-emits button presses for InventoryUI to act on.
class_name InventoryEntry extends VBoxContainer

signal equipPressed(item: Item)
signal usePressed(item: Item)
signal inspectPressed(item: Item)
signal dropPressed(item: Item)

@onready var _nameLabel: Label = $TitleGridContainer/ItemName
@onready var _amountLabel: Label = $TitleGridContainer/ItemAmount
@onready var _weightLabel: Label = $TitleGridContainer/ItemWeight
@onready var _costLabel: Label = $TitleGridContainer/ItemCost
@onready var _typeLabel: Label = $TitleGridContainer/ItemType
@onready var _shortDescription: RichTextLabel = $ShortDescription
@onready var _equipButton: Button = $ButtonsGridContainer/EquipButton
@onready var _useButton: Button = $ButtonsGridContainer/UseButton
@onready var _inspectButton: Button = $ButtonsGridContainer/InspectButton
@onready var _dropButton: Button = $ButtonsGridContainer/DropButton

var _item: Item


func _ready() -> void:
	_equipButton.pressed.connect(func() -> void: equipPressed.emit(_item))
	_useButton.pressed.connect(func() -> void: usePressed.emit(_item))
	_inspectButton.pressed.connect(func() -> void: inspectPressed.emit(_item))
	_dropButton.pressed.connect(func() -> void: dropPressed.emit(_item))


func setup(stack: ItemStack) -> void:
	_item = stack.item
	# @onready vars aren't resolved until the node enters the tree; guard so the
	# controller can call setup() right after instantiate().
	if not is_node_ready():
		await ready
	_nameLabel.text = _item.name
	_amountLabel.text = "x%d" % stack.quantity
	_weightLabel.text = "%d lbs" % _item.baseWeight
	_costLabel.text = "%d gp" % _item.baseCost
	_typeLabel.text = _typeTag(_item)
	_shortDescription.text = _item.shortDescription
	_equipButton.visible = _item.canEquip
	_useButton.visible = _item.canUse


func _typeTag(item: Item) -> String:
	if item is Weapon:
		return "WPN"
	if item is Armor:
		return "ARM"
	return "ITM"
