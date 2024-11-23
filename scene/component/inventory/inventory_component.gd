class_name InventoryComponent extends Node

@export var size: int = 20
var slots: Array[InventorySlot]

signal inventory_updated

func _ready() -> void:
    slots = []
    for i in range(size):
        slots.append(InventorySlot.new())

func add_item(item: Item, amount: int = 1) -> int:
    var remaining = amount

    if item.is_stackable:
        for slot in slots:
            if remaining <= 0:
                break
            if not slot.is_empty() and slot.item.id == item.id:
                remaining = slot.add_item(item, remaining)

    if remaining > 0:
        for slot in slots:
            if remaining <= 0:
                break
            if slot.is_empty():
                remaining = slot.add_item(item, remaining)

    inventory_updated.emit()
    return remaining

func remove_item(item_id: String, amount: int = 1) -> int:
    var remaining = amount

    for slot in slots:
        if remaining <= 0:
            break
        if not slot.is_empty() and slot.item.id == item_id:
            remaining -= slot.remove_item(remaining)

    inventory_updated.emit()
    return amount - remaining

func has_item(item_id: String, amount: int = 1) -> bool:
    var count = 0

    for slot in slots:
        if not slot.is_empty() and slot.item.id == item_id:
            count += slot.quantity
            if count >= amount:
                return true

    return false

func get_item_count(item_id: String) -> int:
    var count = 0

    for slot in slots:
        if not slot.is_empty() and slot.item.id == item_id:
            count += slot.quantity

    return count
