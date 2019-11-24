extends "res://Character.gd"

export var VIEW_DISTANCE = 10.0
export var ATTACK_DIST = 0.5
export var LETOFF_DISTANCE = 0.2
export var FAR_TELEPORT_DISTANCE = 6.0
export var FAR_TELEPORT_TARGET_DISTANCE = 4.5
export var NEAR_TELEPORT_DISTANCE = 3.0
export var ATTACK_DURATION = 1.5

enum STATE {
	WAIT,
	CHASE,
	ATTACK,
}

var state_update_funcs = {}
var state_data = {}
var current_state = STATE.WAIT

func is_in_range(position, distance):
	var rel = position - get_translation()

	if rel.length() > distance:
		return false

	# Looking into different direction as relative vector (away from player)
	#if get_global_transform().basis.x.dot(rel) < 0:
	#	return false

	return true

func is_position_visible(position, distance):
	if !is_in_range(position, distance):
		return false
	print("is_in_range!")

	var space_state = get_world().direct_space_state
	var hit = space_state.intersect_ray(get_translation(), position, [self])
	return hit.empty() # No line of sight

func is_player_visible(player, distance):
	if !is_in_range(player.get_translation(), distance):
		return false

	var space_state = get_world().direct_space_state
	var hit = space_state.intersect_ray(get_translation(), player.get_translation(), [self, player])
	return hit.empty() # No line of sight

func state_init_wait():
	print("state_init_wait")
	return STATE.WAIT

func state_update_wait(delta):
	var players = get_tree().get_nodes_in_group("player")

	# Transitions
	for player in players:
		print("Check player", player)
		if is_player_visible(player, VIEW_DISTANCE):
			return state_init_chase(player)

	# State Update
	return STATE.WAIT

func teleport_towards(player, distance):
	var dir = (player.get_translation() - get_translation()).normalized()
	teleport(dir)

func state_init_chase(player):
	print("state_init_chase")
	state_data[STATE.CHASE] = {
		"chased_player": player,
		"last_seen_position": player.get_translation(),
	}
	return STATE.CHASE

func state_update_chase(delta):
	var data = state_data[STATE.CHASE]
	var pos = get_translation()

	# Transitions
	if is_player_visible(data["chased_player"], ATTACK_DIST):
		print("ATTACK")
		return state_init_attack()
	if (data["last_seen_position"] - pos).length() < LETOFF_DISTANCE:
		print("LETOFF")
		return STATE.WAIT

	# State update
	var chased_player = data["chased_player"]
	if is_player_visible(data["chased_player"], VIEW_DISTANCE):
		data["last_seen_position"] = data["chased_player"].get_translation()
	else:
		# We don't see the player, but we might see that last teleports
		for i in range(chased_player.last_teleports.size() - 1, -1, -1):
			var t = chased_player.last_teleports[i]
			if is_position_visible(t["start_pos"], VIEW_DISTANCE):
				data["last_seen_position"] = t["end_pos"]
				break

	var lsp = data["last_seen_position"]
	if (lsp - pos).length() > FAR_TELEPORT_DISTANCE:
		print("far teleport")
		teleport_towards(chased_player, FAR_TELEPORT_TARGET_DISTANCE)
		return STATE.CHASE

	if (lsp - pos).length() < NEAR_TELEPORT_DISTANCE:
		print("near teleport")
		teleport_towards(chased_player, 0)
		return STATE.CHASE

	move_x(sign(chased_player.get_translation().x - pos.x), delta)
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
