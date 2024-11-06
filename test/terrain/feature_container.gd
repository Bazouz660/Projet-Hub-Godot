extends Node3D
class_name FeatureContainer

var multimesh_features: Dictionary = {}  # name: MultiMeshInstance3D
var instanced_features: Dictionary = {}  # name: Array[Node3D]

func clear_features():
	for feature in multimesh_features.values():
		feature.queue_free()
	multimesh_features.clear()
	
	for instances in instanced_features.values():
		for instance in instances:
			instance.queue_free()
	instanced_features.clear()
