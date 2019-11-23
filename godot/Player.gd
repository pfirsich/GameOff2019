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

var markerScene = preload("res://Marker.tscn")

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

func teleport():
    for i in range(TELEPORT_SAMPLES):
        var dist = TELEPORT_DISTANCE * (1 - i / TELEPORT_SAMPLES)
        var dir = Vector3(1, 1, 0).normalized()
        var target = get_translation() + dir * dist;
        if is_pos_valid(target):
            translate(dir * dist)
        break

func mark(position, color):
    var marker = markerScene.instance()
    marker.set_translation(position)
    var mat = marker.get_surface_material(0).duplicate()
    mat.albedo_color = color
    mat.albedo_color.a = 0.4
    marker.set_surface_material(0, mat)
    get_tree().get_root().add_child(marker)

const red = Color(1, 0, 0)
const green = Color(0, 1, 0)
const blue = Color(0, 0, 1)
const yellow = Color(1, 1, 0)
const purple = Color(1, 0, 1)

func is_pos_valid(pos: Vector3):
    print(">>>> is_pos_valid")
    print("Pos:", pos)
    print("Player Pos:", get_translation())
    mark(pos, yellow)
    mark(get_translation(), green)
    var rel = pos - get_translation()
    var trafo = get_transform().translated(rel)

    # false if we are in a wall
    if test_move(trafo, Vector3(0, 0, 0)):
        return false

    var space_state = get_world().direct_space_state
    print("Rel:", rel)
    var hit = space_state.intersect_ray(pos, get_translation(), [self])
    # We should actually assert !hit.empty() here, because it should never be empty.
    # But we don't want games to crash because of this, so just return false instead.
    if hit.empty():
        return false
    print("Normal:", hit)
    mark(hit["position"], blue)
    var rev_hit = space_state.intersect_ray(get_translation(), pos, [self])
    print("From player to teleport position:", rev_hit)
    # rel points from the the player to teleport position.
    # We have to hit a face with a normal pointing along the ray vector to be outside of the mesh.
    return hit["normal"].dot(rel) > 0

