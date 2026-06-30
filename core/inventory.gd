## the player's inventory data store (autoload singleton). holds no UI and no world
## logic — it only tracks which items the player carries and how many. emits
## EventBus.inventoryChanged whenever the contents change so the UI can rebuild.
extends Node

## one entry per distinct item; identical items stack via quantity. read-only for
## callers — use addItem/removeItem to mutate so the change signal fires.
var stacks: Array[ItemStack] = []


func addItem(item: Item, amount: int = 1) -> void:
	if item == null or amount <= 0:
		return
	var existing: ItemStack = _findStack(item)
	if existing != null:
		existing.quantity += amount
	else:
		var stack: ItemStack = ItemStack.new()
		stack.item = item
		stack.quantity = amount
		stacks.append(stack)
	EventBus.inventoryChanged.emit()


func removeItem(item: Item, amount: int = 1) -> void:
	if item == null or amount <= 0:
		return
	var existing: ItemStack = _findStack(item)
	if existing == null:
		return
	existing.quantity -= amount
	if existing.quantity <= 0:
		stacks.erase(existing)
	EventBus.inventoryChanged.emit()


func getStacks() -> Array[ItemStack]:
	return stacks


## matches by resource path (so two loads of the same .tres stack together), falling
## back to instance identity for runtime-built resources with no path.
func _findStack(item: Item) -> ItemStack:
	for stack: ItemStack in stacks:
		if stack.item == item:
			return stack
		if not item.resource_path.is_empty() and stack.item.resource_path == item.resource_path:
			return stack
	return null
