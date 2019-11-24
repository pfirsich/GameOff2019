extends "res://Character.gd"

export var TELEPORT_LOG_TIMEOUT = 1.5

export var has_upgrade_teleport = true

var last_teleports = []

func _ready():
    char_init()

func _process(delta):
    if Input.is_action_just_pressed("jump"):# and is_on_floor():
        jump()

func get_teleport_dir():
    var camera = get_viewport().get_camera()
    var mouse_pos = get_viewport().get_mouse_position()
    var ray_orig = camera.project_ray_origin(mouse_pos)
    var ray_dir = camera.project_ray_normal(mouse_pos)
    var t = -ray_orig.z / ray_dir.z # ray_orig.z + ray_dir.z * t = 0
    var point_in_z0plane = ray_orig + t * ray_dir
    #return Vector3(1, 0, 0).normalized()
    return (point_in_z0plane - get_translation()).normalized()

func _physics_process(delta):
    move_x(int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")), delta)
    apply_gravity(delta)
    integrate(delta)

    if has_upgrade_teleport and Input.is_action_just_pressed("teleport"):
        var start_pos = get_translation()
        teleport(get_teleport_dir())
        last_teleports.push_back({
            "start_pos": start_pos,
            "end_pos": get_translation(),
            "lifetime": TELEPORT_LOG_TIMEOUT,
        })

    for lt in last_teleports:
        lt["lifetime"] -= delta
    while !last_teleports.empty() && last_teleports.front()["lifetime"] <= 0:
        last_teleports.pop_front()
