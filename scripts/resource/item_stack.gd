extends Resource
class_name ItemStack

@export var item: Item
@export var quantity: int = 1

func _init(p_item: Item = null, p_quantity: int = 1) -> void:
    item = p_item
    quantity = p_quantity

func can_add(amount: int) -> bool:
    if !item.is_stackable:
        return false
    return quantity + amount <= item.max_stack_size

func add(amount: int) -> int:
    if !item.is_stackable:
        return 0

    var space_left = item.max_stack_size - quantity
    var amount_to_add = min(amount, space_left)
    quantity += amount_to_add

    return amount - amount_to_add

func remove(amount: int) -> int:
    var amount_to_remove = min(amount, quantity)
    quantity -= amount_to_remove

    return amount_to_remove
