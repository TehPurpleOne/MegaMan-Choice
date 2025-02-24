extends Camera2D

class_name GameCamera

var target: Player

enum states {
	NULL,
	INITIALIZE,
	ACTIVE,
	STARTTRANSITION,
	TRANSITIONCHECK,
	ENDTRANSITION,
	SNAP
}

var current_state: states = states.NULL
var previous_state: states = states.NULL

var transition_time: float = 1.0

var save_top: int = 0
var save_bottom: int = 0
var save_left: int = 0
var save_right: int = 0

var active_section: Section

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_tree().get_nodes_in_group("Player")[0]

func _physics_process(delta: float) -> void:
	if current_state != states.NULL:
		_state_logic(delta)
		var t: states = _get_transition(delta)
		if t != states.NULL:
			_set_state(t)

func _state_logic(delta: float) -> void:
	match current_state:
		states.ACTIVE:
			# Follow the target.
			global_position = target.global_position

func _get_transition(delta: float) -> states:
	match current_state:
		states.INITIALIZE:
			if target != null: return states.ACTIVE
			
	return states.NULL

func _enter_state(new_state: states, old_state: states):
	match new_state:
		states.INITIALIZE:
			target = get_tree().get_nodes_in_group("Player")[0]

func _exit_state(old_state: states, new_state: states):
	pass

func _set_state(new_state: states):
	previous_state = current_state
	current_state = new_state
	
	_exit_state(previous_state, current_state)
	_enter_state(current_state, previous_state)
	
func _transition(section: Section) -> void:
	print("Transition has started!")
	_set_state(states.STARTTRANSITION)
	var m: Master = get_tree().get_nodes_in_group("Master")[0]
	
	# Add functions to despawn unneeded objects here, then spawn the objects needed for the next section.
	
	# A mask may be necessary to prevent players from seeing previous rooms if a shake function is made.
	
	var direction: Vector2 = section.transition_dir
	var old_cam_position = get_screen_center_position()
	
	limit_top = -1000000000
	limit_bottom = 1000000000
	limit_left = -1000000000
	limit_right = 1000000000
	
	var transition_position: float = 0
	
	match direction:
		Vector2.UP:
			transition_position = section.limit_bottom
		Vector2.DOWN:
			transition_position = section.limit_top
		Vector2.LEFT:
			transition_position = section.limit_right
		Vector2.RIGHT:
			transition_position = section.limit_left
	
	print("Transition position is: ",transition_position)
	
	global_position = old_cam_position
	
	var target_position: Vector2
	
	if direction.x != 0:
		target_position = Vector2(transition_position + m.game_res.x / 2 * direction.x, global_position.y)
	else:
		target_position = Vector2(global_position.x, transition_position + m.game_res.y / 2 * direction.y)
	
	var tween: Tween = create_tween()
	
	print("Transition tween created. Setting animation settings.")
	
	tween.tween_property(self, "global_position", target_position, transition_time)
	tween.set_trans(tween.TransitionType.TRANS_LINEAR)
	tween.set_ease(tween.EaseType.EASE_IN_OUT)
	
	# We're going to grab the player's hitbox size. This is just in case additional players are added
	# later, so we don't have to go back and edit the code if the box is smaller or larger.
	var box: CollisionShape2D = target.get_child(1)
	var box_shape: RectangleShape2D = box.shape
	var player_movement: Vector2
	var player_box_size: Vector2 = box_shape.size / 2
	
	if direction.x != 0:
		var a: Vector2 = player_box_size.x * 2.5 * direction
		var b: Vector2 = Vector2(transition_position - target.global_position.x, 0) * 1.6
		player_movement = target.global_position + (a + b)
	else:
		var a: Vector2 = player_box_size.y * 2 * direction
		var b: Vector2 = Vector2(0, transition_position - target.global_position.x) * 1.6
		player_movement = target.global_position + (a + b)
	
	tween.parallel()
	tween.tween_property(target, "global_position", player_movement, transition_time)
	tween.set_trans(tween.TransitionType.TRANS_LINEAR)
	tween.set_ease(tween.EaseType.EASE_IN_OUT)
	
	await tween.finished
	
	print("Transition completed. Finishing up.")
	
	if section.seal_previous_section:
		active_section._set_seal(true)
		section.seal_previous_section = false
		
	active_section.active = false
	_set_active_section(section)
	_set_state(states.TRANSITIONCHECK)

func _set_active_section(section: Section) -> void:
	if active_section != null:
		active_section.active = false
		
		if section == null:
			print("Cleared active section.")
			active_section = null
			return
	
	# It may be necessary to run another despawn function here, but we'll find out with testing.
	
	active_section = section
	active_section.active = true
	
	var gw: GameWorld = get_tree().get_first_node_in_group("GameWorld")
	gw.active_section = active_section
	
	_update_limits()

func _update_limits() -> void:
	limit_top = active_section.limit_top
	limit_bottom = active_section.limit_bottom
	limit_left = active_section.limit_left
	limit_right = active_section.limit_right
	
	# I save these values here in case the camera gains a shake function.
	save_top = limit_top
	save_bottom = limit_bottom
	save_left = limit_left
	save_right = limit_right
	
	print("Camera limits are now: ",limit_top,", ",limit_bottom,", ",limit_left,", ",limit_right)
