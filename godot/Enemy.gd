extends "res://Character.gd"

export var VIEW_DISTANCE = 10.0
export var ATTACK_DIST = 0.5
export var LETOFF_DISTANCE = 0.2
export var FAR_TELEPORT_DISTANCE = 6.0
export var FAR_TELEPORT_TARGET_DISTANCE = 4.5
export var NEAR_TELEPORT_DISTANCE = 3.0
export var ATTACK_DURATION = 1.5
export var TELEPORT_REACTION_TIME = 1.5
export var GROUND_RAYCAST_LOOKAHEAD = 0.5
export var GROUND_RAYCAST_LENGTH = 2.0
export var MOVE_X_THRESH = 0.2

enum STATE {
    WAIT,
    CHASE,
    ATTACK,
}

enum EVENT {
    TELEPORT,
}

var state_update_funcs = {}
var state_data = {}
var current_state = STATE.WAIT
var event_queue = []

func is_in_range(position, distance):
    var rel = position - get_translation()

    if rel.length() > distance:
        return false

    # Looking into different direction as relative vector (away from player)
    #if get_global_transform().basis.x.dot(rel) < 0:
    #	return false

    return true

func is_position_visible(position, distance=null):
    if distance == null:
        distance = VIEW_DISTANCE

    if !is_in_range(position, distance):
        return false
    print("is_in_range!")

    return raycast_level(get_translation(), position).empty() # No line of sight

func is_player_visible(player, distance=null):
    if distance == null:
        distance = VIEW_DISTANCE

    if !is_in_range(player.get_translation(), distance):
        return false

    return raycast_level(get_translation(), player.get_translation()).empty() # No line of sight

func state_init_wait():
    print("state_init_wait")
    return STATE.WAIT

func state_update_wait(delta):
    var players = get_tree().get_nodes_in_group("player")

    for player in players:
        if is_player_visible(player, VIEW_DISTANCE):
            return state_init_chase(player)

    move_x(0, delta) # brake
    return STATE.WAIT

func teleport_towards(player, distance):
    var dir = (player.get_translation() - get_translation()).normalized()
    teleport(dir)

func state_init_chase(player, last_seen_position=null):
    print("state_init_chase")
    if last_seen_position == null:
        last_seen_position = player.get_translation()
    state_data[STATE.CHASE] = {
        "chased_player": player,
        "last_seen_position": last_seen_position,
    }
    return STATE.CHASE

func state_update_chase(delta):
    var data = state_data[STATE.CHASE]
    var chased_player = data["chased_player"]
    var lsp = data["last_seen_position"]
    var pos = get_translation()

    if is_player_visible(chased_player, ATTACK_DIST):
        return state_init_attack()

    if is_player_visible(chased_player):
        print("visible - chase!")
        lsp = chased_player.get_translation()
        data["last_seen_position"] = lsp
        if (lsp - pos).length() > FAR_TELEPORT_DISTANCE:
            # only on similar height
            # if the player is visible on a different height,
            # it will probably not be visible for long and we will not
            # teleport into the air
            if abs(lsp.y - pos.y) <= 0.1: # whatever
                var teleport_vec = FAR_TELEPORT_TARGET_DISTANCE * (lsp - pos).normalized()
                teleport(pos + teleport_vec)
    else:
        print("TELEPORT")
        teleport(lsp)
        return STATE.CHASE

    var ahead = Vector3(velocity.x, 0.0, 0.0).normalized()
    var start_pos = get_translation() + GROUND_RAYCAST_LOOKAHEAD * ahead
    var end_pos = start_pos - Vector3(0, GROUND_RAYCAST_LENGTH, 0)
    var hit = raycast_level(start_pos, end_pos)
    mark(start_pos, "g")
    mark(end_pos, "b")
    if !hit.empty(): # don't run off cliffs
        var delta_x = lsp.x - pos.x
        if abs(delta_x) > MOVE_X_THRESH:
            print("move")
            move_x(sign(delta_x), delta)
        else:
            print("wait")
            return STATE.WAIT
    else:
        print("cliff")

    return STATE.CHASE

func state_init_attack():
    print("state_init_attack")
    state_data[STATE.ATTACK] = {
        "timeout": ATTACK_DURATION
    }
    return STATE.ATTACK

func state_update_attack(delta):
    if state_data[STATE.ATTACK]["timeout"] <= 0:
        return state_init_wait()

    state_data[STATE.ATTACK]["timeout"] -= delta
    move_x(0, delta) # brake
    return STATE.ATTACK

func _ready():
    char_init()
    state_update_funcs = {
        STATE.WAIT: funcref(self, "state_update_wait"),
        STATE.CHASE: funcref(self, "state_update_chase"),
        STATE.ATTACK: funcref(self, "state_update_attack"),
    }

func _process(delta):
    pass

func _physics_process(delta):
    current_state = state_update_funcs[current_state].call_func(delta)
    apply_gravity(delta)
    integrate(delta)

    for event in event_queue:
        event["timeout"] -= delta

    while !event_queue.empty() and event_queue.front()["timeout"] <= 0:
        var event = event_queue.front()
        match event["type"]:
            EVENT.TELEPORT:
                current_state = state_init_chase(event["player"], event["to_pos"])
        event_queue.pop_front()

func on_Player_teleport(player, from_pos, to_pos):
    if is_position_visible(from_pos):
        event_queue.push_back({
            "type": EVENT.TELEPORT,
            "timeout": TELEPORT_REACTION_TIME,
            "player": player,
            "from_pos": from_pos,
            "to_pos": to_pos,
        })
