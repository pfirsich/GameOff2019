extends Skeleton

var animationPlayer = null;

func _ready():
    animationPlayer = $AnimationPlayer
    animationPlayer.playback_speed = 1.8
    animationPlayer.get_animation("Run").set_loop(true)