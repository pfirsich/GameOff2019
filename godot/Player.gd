extends KinematicBody

export var ACCEL = 10.0
export var MAX_SPEED = 4.0
export var FRICTION = 0.5 # seconds until MAX_SPEED goes to 0
export var JUMP_HEIGHT = 1.0
export var JUMP_DURATION = 0.5
export var TURNAROUND_ACCEL_FACTOR = 3.0
export var TELEPORT_DISTANCE = 4.0
export var TELEPORT_SAMPLES = 16

export var has_teleport = true;

var velocity = Vector2()
var gravity
var jump_vel

func _ready():
    var jump_dur_half = JUMP_DURATION / 2.0
    jump_vel = 2 * JUMP_HEIGHT / jump_dur_half
    gravity = jump_vel / jump_dur_half

func _process(delta):
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_vel

    if Input.is_action_just_pressed("teleport"):
        teleport()

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

func teleport():
    for i in range(TELEPORT_SAMPLES):
        var progress = TELEPORT_DISTANCE / TELEPORT_SAMPLES * i
        var dist = TELEPORT_DISTANCE - progress
        var dir = Vector3(1, 0, 0)
        var target = get_translation() +  dir * dist;

        if is_pos_valid(target):
            set_translation(target)

func is_pos_valid(pos: Vector3):
    var rel = pos - get_translation()
    var trafo = get_transform().translated(rel)
    return !test_move(trafo, Vector3(0, 0, 0))

