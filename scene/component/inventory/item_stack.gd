extends RefCounted
class_name ItemStack

var item_id: String
var quantity: int
var max_stack_size: int
var slot_index: int # Track which slot this stack belongs to

func _init(p_item_id: String = "", p_quantity: int = 1, p_max_stack_size = 1, p_slot_index: int = -1) -> void:
    item_id = p_item_id
    quantity = p_quantity
    slot_index = p_slot_index
    max_stack_size = p_max_stack_size

func can_add(amount: int) -> bool:
    var item = ItemRegistry.get_item_by_id(item_id)
    if not item.is_stackable or quantity + amount > max_stack_size:
        return false
    return true

func add(amount: int) -> int:
    var item = ItemRegistry.get_item_by_id(item_id)
    if not item.is_stackable:
        return amount
    quantity += amount
    return 0

func remove(amount: int) -> int:
    var removed = min(amount, quantity)
    quantity -= removed
    return removed