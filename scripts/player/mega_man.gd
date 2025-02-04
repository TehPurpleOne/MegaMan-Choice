extends "res://scripts/player/player.gd"

class_name MegaMan

enum states {
	NULL,
	RESET,
	TOPSCREEN,
	BEAMIN,
	BEAMOUT,
	APPEAR,
	LEAVE,
	IDLE,
	LILSTEP,
	RUN,
	JUMP,
	CLIMB,
	TOP,
	SLIDE,
	HURT,
	IDLESHOT,
	RUNSHOT,
	JUMPSHOT,
	CLIMBSHOT,
	IDLETHROW,
	JUMPTHROW,
	CLIMBTHROW
}

var no_flip_states := [ # These states will trigger the no_flip flag
		states.NULL,
		states.RESET,
		states.TOPSCREEN,
		states.BEAMIN,
		states.BEAMOUT,
		states.APPEAR,
		states.LEAVE,
		states.CLIMB,
		states.TOP
	]

var current_state: states = states.NULL
var previous_state: states = states.NULL

func _ready() -> void:
	im = get_node("/root/im")
	gw = get_tree().get_first_node_in_group("GameWorld")
	_set_state(states.RESET)

func _process(delta: float) -> void:
	if $Sprite2D.flip_h != current_flip: $Sprite2D.flip_h = current_flip

func _physics_process(delta: float) -> void:
	if current_state != states.NULL:
		_state_logic(delta)
		var t: states = _get_transition(delta)
		if t != states.NULL:
			_set_state(t)

func _state_logic(delta: float) -> void:
	if !no_flip: 
		# Flip the character sprite if needed.
		if im.get_x_dir() == -1: current_flip = true
		if im.get_x_dir() == 1: current_flip = false
	
	match current_state: # Apply gravity to the following states.
		states.BEAMIN, states.BEAMOUT, states.IDLE, states.LILSTEP, states.RUN, states.JUMP, states.SLIDE, states.HURT, states.IDLESHOT, states.RUNSHOT, states.JUMPSHOT, states.IDLETHROW, states.JUMPTHROW:
			apply_gravity(delta)
	
	match current_state: # Apply horizontal movement to the following states.
		states.IDLE, states.RUN, states.JUMP, states.SLIDE, states.IDLESHOT, states.RUNSHOT, states.JUMPSHOT, states.JUMPTHROW:
			apply_horizontal(delta)
		
	match current_state: # Halt horizontal movement to the following states.
		states.IDLETHROW, states.LILSTEP, states.CLIMB, states.TOP, states.CLIMBSHOT, states.CLIMBTHROW:
			if velocity.x != 0: velocity.x = 0
		
	match current_state: # Individual state functions and checks.
		states.BEAMIN:
			var dist: float = abs(global_position.y - spawn_y_pos)
			#Re-enable the hitbox so the player can land without issue.
			if dist <= 20 && $CollisionShape2D.disabled: $CollisionShape2D.disabled = false
		
		states.JUMP:
			if velocity.y < -2 && im.is_action_released("a"): velocity.y = -2
	
	# Move the player.
	move_and_slide()
	# Prevent the player from moving offscreen.
	if gw.active_section != null: global_position.x = clamp(global_position.x, gw.active_section.x_clamp_low, gw.active_section.x_clamp_high)

func _get_transition(delta: float) -> states:
	match current_state:
		states.RESET:
			if global_position != Vector2.ZERO && gw.active_section != null: return states.TOPSCREEN
		
		states.TOPSCREEN:
			if gw.current_state == GameWorld.states.RUN: return states.BEAMIN
		
		states.BEAMIN:
			if is_on_floor(): return states.APPEAR
		
		states.IDLE:
			# If the player presses the jump button, jump
			if im.is_action_pressed("a") && jumps_left > 0 || !is_on_floor(): return states.JUMP
			# If the player presses a direction, start the walk cycle.
			if im.get_x_dir() != 0: return states.LILSTEP
		
		states.RUN:
			# If the player presses the jump button, jump
			if im.is_action_pressed("a") && jumps_left > 0 || !is_on_floor(): return states.JUMP
			# If the player stops moving, return to idle.
			if im.get_x_dir() == 0: return states.LILSTEP
			
		states.JUMP:
			# Check to see if the player has landed.
			if is_on_floor() && im.get_x_dir() == 0: return states.IDLE
			if is_on_floor() && im.get_x_dir() != 0: return states.RUN
	return states.NULL

func _enter_state(new_state: states, old_state: states) -> void:
	no_flip = new_state in no_flip_states # Set the no_flip flag
	
	match new_state:
		states.RESET:
			jumps_left = max_jumps
			
		states.TOPSCREEN:
			# Set the player's position above the play field for the teleport animation.
			global_position.y = gw.active_section.limit_top - 12
			$CollisionShape2D.disabled = true # Disable the hit bos so Rock can move through obstacles if necessary
			
		states.JUMP:
			velocity.y = jump_str
			jumps_left -= 1

	# Grab the state name for the animation player.
	var state_name: String = ""
	for stname in states.keys():
		if states[stname] == current_state: state_name = stname;
		
	if $AnimationPlayer.has_animation(state_name): $AnimationPlayer.play(state_name)
	

func _exit_state(old_state: states, new_state: states) -> void:
	match old_state:
		states.JUMP:
			jumps_left = max_jumps

func _set_state(new_state: states) -> void:
	previous_state = current_state
	current_state = new_state
	
	for stname in states.keys():
		if states[stname] == current_state: print(name,", is now in state: ",stname);
	
	ticker = 0
	
	_exit_state(previous_state, current_state)
	_enter_state(current_state, previous_state)


func _on_anim_done(anim_name: StringName) -> void:
	match anim_name:
		"APPEAR":
			_set_state(states.IDLE)
		
		"LILSTEP":
			if im.get_x_dir() != 0: _set_state(states.RUN)
			else: _set_state(states.IDLE)
