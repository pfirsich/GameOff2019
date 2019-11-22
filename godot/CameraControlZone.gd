extends Area

export(NodePath) var target_node = null
export var distance = 10.0
export var height = 6.0

func _on_Area_body_entered(body):
    # Control which objects take control of the camera with collision masks
    get_tree().call_group("camera", "take_control", self)

func _on_Area_body_exited(body):
    get_tree().call_group("camera", "release_control", self)
