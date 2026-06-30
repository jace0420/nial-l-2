## a quantity of one Item resource in the inventory. identical items (same .tres)
## share a single stack rather than appearing as separate entries.
class_name ItemStack extends RefCounted

var item: Item
var quantity: int = 1
