extends CollisionShape

export(NodePath) var target_node = null
export var distance = 10
export var height = 6

# Called when the node enters the scene tree for the first time.
func _ready():
    pass
    #Camera.connect("take_control", self, "_on_CameraControlZone_take_control")
    #$Camera.connect("release_control", self, "_on_CameraControlZone_release_control")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Area_body_entered(body):
    # Control which objects take control of the camera with collision masks
    get_tree().call_group("camera", "take_control", self)

func _on_Area_body_exited(body):
    get_tree().call_group("camera", "release_control", self)
