extends KinematicBody

export var ACCEL = 10.0
export var MAX_SPEED = 4.0
export var FRICTION = 0.5 # seconds until MAX_SPEED goes to 0
export var JUMP_HEIGHT = 1.0
export var JUMP_DURATION = 0.5
export var TURNAROUND_ACCEL_FACTOR = 3.0
export var TELEPORT_DISTANCE = 4.0
export var TELEPORT_VELOCITY = 2.0

export var show_markers = false

var velocity = Vector2()
var gravity
var jump_vel

func char_init():
    var jump_dur_half = JUMP_DURATION / 2.0
    jump_vel = 2 * JUMP_HEIGHT / jump_dur_half
    gravity = jump_vel / jump_dur_half
    set_axis_lock(PhysicsServer.BODY_AXIS_LINEAR_Z, true)

func jump():
    if Input.is_action_just_pressed("jump"):# and is_on_floor():
        velocity.y = jump_vel

func zero_z(vec : Vector3):
    vec.z = 0
    return vec

func move_x(dir, delta):
    var accel = ACCEL
    if sign(velocity.x) != sign(dir):
        accel *= TURNAROUND_ACCEL_FACTOR
    velocity.x += dir * accel * delta

    if abs(velocity.x) > MAX_SPEED:
        velocity.x = sign(velocity.x) * MAX_SPEED

    if dir == 0:
        var friction = -sign(velocity.x) * MAX_SPEED / FRICTION * delta
        if sign(velocity.x) != sign(velocity.x + friction):
            velocity.x = 0
        else:
            velocity.x += friction

func apply_gravity(delta):
    if !is_on_floor():
        velocity.y += -gravity * delta

func integrate(delta):
    move_and_slide(Vector3(velocity.x, velocity.y, 0), Vector3(0, 1, 0), true)
    set_translation(zero_z(get_translation()))

func mark(pos, col):
    if show_markers:
        get_node("../MarkerSpawner").mark(pos, col)

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

func teleport(teleport_dir):
    # zero z everywhere to glitch out less
    teleport_dir = zero_z(teleport_dir)
    var teleport_pos = zero_z(get_teleport_pos(teleport_dir))
    mark(teleport_pos, "r")
    set_translation(teleport_pos)
    # TODO: Teleport into floor (diagonal). Slide?
    move_and_collide(teleport_dir * 1e-2)
    velocity = TELEPORT_VELOCITY * teleport_dir
