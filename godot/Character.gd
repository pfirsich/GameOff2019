extends KinematicBody

const CHECK_INSIDE_DEPTH = 5.0
const CUSHION_DIR_COUNT = 4.0

export var ACCEL = 10.0
export var MAX_SPEED = 4.0
export var FRICTION = 0.5 # seconds until MAX_SPEED goes to 0
export var JUMP_HEIGHT = 1.0
export var JUMP_DURATION = 0.5
export var TURNAROUND_ACCEL_FACTOR = 3.0
export var TELEPORT_DISTANCE = 4.0
export var TELEPORT_VELOCITY = 2.0
export var CUSHION_SIZE = 0.35

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
    # If we are inside a wall, don't move or apply gravity, just allow teleports outside
    if !is_inside(get_translation()):
        move_and_slide(Vector3(velocity.x, velocity.y, 0), Vector3(0, 1, 0), true)
        set_translation(zero_z(get_translation()))

func mark(pos, col):
    if show_markers:
        get_node("../MarkerSpawner").mark(pos, col)

func is_inside(position):
    var space_state = get_world().direct_space_state
    var pos = get_translation()
    var hit = space_state.intersect_ray(pos, pos + CHECK_INSIDE_DEPTH * Vector3(0, 0, 1), [self])
    return !hit.empty() # hit => we are inside

func get_teleport_pos(teleport_dir):
    var target_pos = get_translation() + teleport_dir * TELEPORT_DISTANCE
    mark(target_pos, "y")
    var last_hit = {"position": get_translation(), "normal": teleport_dir}
    var space_state = get_world().direct_space_state
    var inside = is_inside(get_translation())
    while true: # TODO: limit this?
        # Add some bias to the starting position, so we don't start
        # inside the polygon when we start from a later hit
        var start_pos = last_hit["position"] + 1e-5*teleport_dir
        var hit = space_state.intersect_ray(start_pos, target_pos, [self])
        if !hit.empty():
            mark(hit["position"], "g")
            last_hit = hit
            inside = !inside
        else:
            if inside: # Target position is inside a mesh, return last hit
                return last_hit["position"] + 1e-1*last_hit["normal"] # but move away from the wall a bit
            else: # Target position is not inside a mesh! We can go there directly
                return target_pos

# We move away from walls to glitch less
func apply_cushion():
    var space_state = get_world().direct_space_state
    for i in range(CUSHION_DIR_COUNT):
        var angle = i / CUSHION_DIR_COUNT * PI * 2.0
        var dir = Vector3(cos(angle), sin(angle), 0.0)
        var pos = get_translation()
        var hit = space_state.intersect_ray(pos, pos + CUSHION_SIZE * dir, [self])
        if !hit.empty():
            var push_dist = CUSHION_SIZE - (hit["position"] - pos).length()
            set_translation(pos - push_dist * dir)

func teleport(teleport_dir):
    var backup_pos = get_translation()
    # zero z everywhere to glitch out less
    teleport_dir = zero_z(teleport_dir)
    var teleport_pos = zero_z(get_teleport_pos(teleport_dir))
    mark(teleport_pos, "r")
    set_translation(teleport_pos)
    teleport_pos = apply_cushion()
    mark(get_translation(), "p")
    # TODO: Teleport into floor (diagonal). Slide?
    move_and_collide(teleport_dir * 1e-2)
    # If we fucked up, just undo the teleport (add feedback later)
    if is_inside(get_translation()):
        print("FUCKED UP TELEPORT. UNDO!")
        set_translation(backup_pos)
    else:
        velocity = TELEPORT_VELOCITY * teleport_dir
