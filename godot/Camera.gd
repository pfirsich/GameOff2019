extends Camera

export var DEFAULT_DISTANCE = 3.5
export var DEFAULT_HEIGHT = 1.5

export var CAMERA_INTERP_SPEED = 4.0
export(Vector2) var CAMERA_DEADZONE = Vector2(0.2, 0.2)

var camera_control_zone : Node = null
var target_node : Spatial = null
var distance
var height

func _ready():
    distance = DEFAULT_DISTANCE
    height = DEFAULT_HEIGHT

func _process(delta):
    if target_node == null:
        target_node = get_node("../Player")
    var target_pos = target_node.get_translation()
    var target_cam_pos = Vector3(target_pos.x, target_pos.y + height, distance)

    var delta_vec = target_cam_pos - translation
    if abs(delta_vec.x) < CAMERA_DEADZONE.x:
        delta_vec.x = 0
    if abs(delta_vec.y) < CAMERA_DEADZONE.y:
        delta_vec.y = 0
    #delta_vec = delta_vec.normalized()
    translate(delta_vec * CAMERA_INTERP_SPEED * delta)
    look_at(target_pos, Vector3(0, 1, 0))

func take_control(control_zone):
    camera_control_zone = control_zone
    if control_zone.target_node:
        target_node = get_node(control_zone.target_node)
    else:
        target_node = $Player

func release_control(control_zone):
    if camera_control_zone == control_zone:
        camera_control_zone = null
        target_node = null
        distance = DEFAULT_DISTANCE
        height = DEFAULT_HEIGHT
