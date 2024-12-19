extends Node3D
class_name DroppedItem

@onready var mesh_container := %MeshContainer as Node3D
@onready var area := %InteractArea as Area3D
@onready var label := $Label as Label
@onready var label_target := %LabelTarget as Marker3D

var item_id: String = ""
var quantity = 0
var item_visuals: PackedScene
var created_at: int # Add timestamp for creation

func _ready():
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)

	item_id = name.split("?")[0]
	print("Dropped item ID: " + item_id)
	quantity = name.split("?")[1].to_int()
	item_visuals = ItemRegistry.get_item_by_id(item_id).model
	created_at = Time.get_ticks_msec() # Store creation time

	mesh_container.add_child(item_visuals.instantiate())
	label.text = str(item_id) + " x" + str(quantity)
	label.hide()

func _process(_delta):
	if label.is_visible_in_tree():
		var camera := get_viewport().get_camera_3d()
		var screen_pos = camera.unproject_position(label_target.global_position)
		label.global_position = screen_pos - (label.size / 2)

func _on_area_entered(p_area: Area3D) -> void:
	if p_area.is_in_group("player"):
		label.show()
		p_area.interacted.connect(_on_interact)
		print("Player entered the item area.")


	if p_area.is_in_group("ground_item") and p_area.get_parent() != self:
		var other_item = p_area.get_parent() as DroppedItem
		if other_item and other_item.item_id == item_id:
			# Only the newer item should initiate the merge
			if created_at > other_item.created_at:
				merge_stack(other_item)

func merge_stack(other_item: DroppedItem) -> void:
	quantity += other_item.quantity
	label.text = str(item_id) + " x" + str(quantity)
	other_item.queue_free()
	print("Merged item stack.")

func _on_area_exited(p_area: Area3D) -> void:
	if p_area.is_in_group("player"):
		label.hide()
		p_area.interacted.disconnect(_on_interact)
		print("Player exited the item area.")

func _on_interact(player: Player) -> void:
	var success = player.inventory.add_item_by_id(item_id, quantity)
	if success:
		if MultiplayerManager.is_host:
			queue_free()
		else:
			_delete_self.rpc_id(1)
		print("Player picked up item.")
		return
	print("Failed to pick up item.")

@rpc("any_peer", "call_local", "reliable")
func rpc_set_position(p_position: Vector3) -> void:
	position = p_position

@rpc("any_peer", "call_remote", "reliable")
func _delete_self() -> void:
	queue_free()