extends Control
class_name InventoryUI

@export var inventory_component: InventoryComponent
@export var columns: int = 5

@onready var grid_container: GridContainer = $GridContainer
@onready var slot_scene = preload("res://scene/interface/inventory/inventory_slot_ui.tscn")

func _ready() -> void:
    grid_container.columns = columns
    inventory_component.inventory_updated.connect(_on_inventory_updated)
    _setup_inventory_slots()

    var sword = preload("res://data/item/sword.res")
    var apple = preload("res://data/item/apple.res")
    inventory_component.add_item(sword, 1)
    inventory_component.add_item(apple, 1)

func _setup_inventory_slots() -> void:
    for child in grid_container.get_children():
        child.queue_free()

    for i in range(inventory_component.size):
        var slot_ui = slot_scene.instantiate()
        grid_container.add_child(slot_ui)
        slot_ui.slot_index = i
        slot_ui.slot_clicked.connect(_on_slot_clicked)
        slot_ui.slot_right_clicked.connect(_on_slot_right_clicked)
        
func _on_inventory_updated() -> void:
    _update_slots_display()

func _update_slots_display() -> void:
    var slots = inventory_component.slots
    var slot_uis = grid_container.get_children()
    
    for i in range(slots.size()):
        var slot_data = slots[i]
        var slot_ui = slot_uis[i]
        slot_ui.update_display(slot_data.item, slot_data.quantity)

func _on_slot_clicked(slot_index: int) -> void:
    var slot = inventory_component.slots[slot_index]
    if slot.item:
        print(slot.item.id, " clicked")

func _on_slot_right_clicked(slot_index: int) -> void:
    var slot = inventory_component.slots[slot_index]
    if slot.item:
       print(slot.item.id, " right clicked")
