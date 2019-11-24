extends "res://Character.gd"

export var TELEPORT_DISTANCE = 4.0
export var TELEPORT_LOG_TIMEOUT = 1.5

export var has_upgrade_teleport = true

var last_teleports = []
var animation_player

func _ready():
    char_init()
    animation_player = $PlayerModel/Armature/AnimationPlayer
    animation_player.play("Idle")

func _process(delta):
    if Input.is_action_just_pressed("jump") and is_on_floor():
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
    var dir = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"));

    move_x(dir, delta)
    apply_gravity(delta)
    integrate(delta)

    if has_upgrade_teleport and Input.is_action_just_pressed("teleport"):
        var start_pos = get_translation()
        teleport(get_translation() + TELEPORT_DISTANCE * get_teleport_dir())

        for enemy in get_tree().get_nodes_in_group("enemy"):
            enemy.on_Player_teleport(self, start_pos, get_translation())

        animation_player.playback_speed = 1
        animation_player.play("TeleportExit")

    var idle_velocity_thresh = 0.15

    var anim_speed_interp = abs(velocity.x) / MAX_SPEED
    var run_anim_speed = 0.2 * (1 - anim_speed_interp) + 1.8 * anim_speed_interp
    if velocity.x > idle_velocity_thresh:
        set_rotation(Vector3(0, PI, 0))
        animation_player.playback_speed = run_anim_speed
        animation_player.play("Run")
    elif velocity.x < -idle_velocity_thresh:
        set_rotation(Vector3(0, 0, 0))
        animation_player.playback_speed = run_anim_speed
        animation_player.play("Run")
    else:
        animation_player.playback_speed = 1
        animation_player.play("Idle")
