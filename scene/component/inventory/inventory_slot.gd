class_name InventorySlot extends RefCounted

var item: Item = null
var quantity: int = 0

func is_empty() -> bool:
    return item == null

func can_add_item(new_item: Item, amount: int = 1) -> bool:
    if is_empty():
        return true
    if item.id != new_item.id:
        return false
    if !item.is_stackable:
        return false
    return quantity + amount <= item.max_stack_size

func add_item(new_item: Item, amount: int = 1) -> int:
    if is_empty():
        item = new_item
        quantity = min(amount, item.max_stack_size if item.is_stackable else 1)
        return amount - quantity

    if item.id == new_item.id and item.is_stackable:
        var space_left = item.max_stack_size - quantity
        var added = min(amount, space_left)
        quantity += added
        return amount - added

    return amount

func remove_item(amount: int = 1) -> int:
    if is_empty():
        return 0

    var removed = min(amount, quantity)
    quantity -= removed

    if quantity <= 0:
        item = null
        quantity = 0

    return removed
