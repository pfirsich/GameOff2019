extends KinematicBody

export var GRAVITY = 1.0
export var ACCEL = 10.0

var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
    var moveX = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
    velocity.x += moveX * ACCEL * delta
    velocity.y += -GRAVITY * delta
    move_and_collide(Vector3(velocity.x * delta, velocity.y * delta, 0))
