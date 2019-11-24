extends Skeleton

var animationPlayer = null;

func _ready():
    animationPlayer = $AnimationPlayer
    # Fix animations
    animationPlayer.get_animation("Run").set_loop(true)
    animationPlayer.get_animation("Idle").set_loop(true)
