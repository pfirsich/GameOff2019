extends KinematicBody

export var ACCEL = 10.0
export var MAX_SPEED = 4.0
export var FRICTION = 0.5 # seconds until MAX_SPEED goes to 0
export var JUMP_HEIGHT = 1.0
export var JUMP_DURATION = 0.5
export var TURNAROUND_ACCEL_FACTOR = 3.0
export var TELEPORT_DISTANCE = 4.0
export var TELEPORT_SAMPLES = 16

export var has_upgrade_teleport = true

var velocity = Vector2()
var gravity
var jump_vel

func _ready():
    var jump_dur_half = JUMP_DURATION / 2.0
    jump_vel = 2 * JUMP_HEIGHT / jump_dur_half
    gravity = jump_vel / jump_dur_half

func _process(delta):
    if Input.is_action_just_pressed("jump"):# and is_on_floor():
        velocity.y = jump_vel

func _physics_process(delta):
    var moveX = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
    var accel = ACCEL
    if sign(velocity.x) != sign(moveX):
        accel *= TURNAROUND_ACCEL_FACTOR
    velocity.x += moveX * accel * delta

    if abs(velocity.x) > MAX_SPEED:
        velocity.x = sign(velocity.x) * MAX_SPEED

    if moveX == 0:
        var friction = -sign(velocity.x) * MAX_SPEED / FRICTION * delta

        if sign(velocity.x) != sign(velocity.x + friction):
            velocity.x = 0
        else:
            velocity.x += friction

    if !is_on_floor():
        velocity.y += -gravity * delta

    move_and_slide(Vector3(velocity.x, velocity.y, 0), Vector3(0, 1, 0), true)

    if has_upgrade_teleport and Input.is_action_just_pressed("teleport"):
        teleport()

func mark(pos, col):
    get_node("../MarkerSpawner").mark(pos, col)

func get_teleport_dir():
    var camera = get_viewport().get_camera()
    var mouse_pos = get_viewport().get_mouse_position()
    var ray_orig = camera.project_ray_origin(mouse_pos)
    var ray_dir = camera.project_ray_normal(mouse_pos)
    var t = -ray_orig.z / ray_dir.z # ray_orig.z + ray_dir.z * t = 0
    var point_in_z0plane = ray_orig + t * ray_dir
    #return Vector3(1, 0, 0).normalized()

    return (point_in_z0plane - get_translation()).normalized()

func get_teleport_pos(teleport_dir):
    var target_pos = get_translation() + teleport_dir * TELEPORT_DISTANCE
    mark(target_pos, "y")
    var cur_pos = get_translation()
    var inside = false
    var space_state = get_world().direct_space_state
    while true: # TODO: limit this?
        var hit = space_state.intersect_ray(cur_pos, target_pos, [self])
        if !hit.empty():
            mark(hit["position"], "g")
            inside = !inside
            cur_pos = hit["position"] + 1e-5*teleport_dir# don't start inside the polygon
        else:
            if inside: # Target position is inside a mesh, return last hit
                return cur_pos - 2e-1*teleport_dir
            else: # Target position is not inside a mesh! We can go there directly
                return target_pos

func teleport():
    var teleport_dir = get_teleport_dir()
    var teleport_pos = get_teleport_pos(teleport_dir)
    mark(teleport_pos, "r")
    set_translation(teleport_pos)
    # TODO: Teleport into floor (diagonal). Slide?
    move_and_collide(teleport_dir * 1e-2)
