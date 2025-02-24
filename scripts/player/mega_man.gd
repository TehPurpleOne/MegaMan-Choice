extends "res://scripts/player/player.gd"

class_name MegaMan

func _ready() -> void:
	im = get_node("/root/im")
	gw = get_tree().get_first_node_in_group("GameWorld")
	p_sprite = get_node("Sprite2D")
	
	set_state(states.RESET)

func _process(delta: float) -> void:
	flip_state()
	sprite_offset()
	
func _physics_process(delta: float) -> void:
	if(current_state != states.NULL):
		state_logic(delta)
		var t: states = get_transition(delta)
		if(t != states.NULL):
			set_state(t)

func state_logic(delta: float) -> void:
	input_manager()
	
	var y_vel: Array[states] = [ # States to apply standard gravity to.
		states.BEAMIN,
		states.BEAMOUT,
		states.IDLE,
		states.LILSTEP,
		states.RUN,
		states.JUMP,
		states.SLIDE,
		states.HURT,
		states.FALL
	]
	
	var x_vel: Array[states] = [ #States to apply normal X movment to.
		states.IDLE,
		states.RUN,
		states.JUMP,
		states.SLIDE
	]
	
	for state in y_vel:
		if(y_vel.has(current_state)):
			# Apply the standard gravity functions.
			apply_y(delta)
			break;
		else:
			# Apply situational gravity as needed.
			match current_state:
				states.CLIMB, states.TOP:
					# Ladder velocity goes here.
					pass
				_:
					# Stop Y velocity for everything else.
					stop_y()
			pass
	
	for state in x_vel:
		if(x_vel.has(current_state)):
			# Apply the typical left and right movement
			apply_x()
			break;
		else:
			# Apply situational left/right movement.
			match current_state:
				states.HURT:
					# Hurt logic goes here.
					pass
				_:
					# Stop any other form of X movement.
					if(!ice): stop_x()
	
	# Place state-specific functions here.
	match current_state:
		states.JUMP:
			if(jump_release && !ignore_jump_hold && velocity.y < -30):
				velocity.y = -30
	
	move_and_slide()
	
	if(gw.active_section != null): global_position.x = clamp(global_position.x, gw.active_section.x_clamp_low, gw.active_section.x_clamp_high)

func get_transition(delta: float) -> states:
	match current_state:
		states.RESET:
			if(gw.current_state == GameWorld.states.RUN):
				return states.BEAMIN
		
		states.BEAMIN:
			if(global_position.y >= beam_y_pos):
				return states.APPEARA
		
		states.IDLE:
			if(dir_hold.y != 1 && jump_tap || !is_on_floor()): return states.JUMP
			
			#if(slide_tap): return states.SLIDE
			
			if(dir_hold.x != 0): return states.LILSTEP
		
		states.JUMP:
			if(is_on_floor()):
				match dir_hold.x:
					0:
						return states.IDLE
					_:
						return states.RUN
		states.LILSTEP:
			if(dir_hold.y != 1 && jump_tap || !is_on_floor()): return states.JUMP
			
		states.RUN:
			if(dir_hold.y != 1 && jump_tap || !is_on_floor()): return states.JUMP
			
			#if(slide_tap): return states.SLIDE
			
			if(dir_hold.x == 0): return states.LILSTEP
				
	return states.NULL

func enter_state(new_state: states, old_state: states) -> void:
	# Grab the state name for the animation player.
	var state_name: String = ""
	for stname in states.keys():
		if(states[stname] == new_state): state_name = stname
		
	print(name," has entered state: ",state_name)
	
	# Set the flip state.
	var no_flipping: Array[states] = [
		states.RESET,
		states.BEAMIN,
		states.BEAMOUT,
		states.APPEARA,
		states.APPEARB,
		states.LEAVEA,
		states.LEAVEB,
		states.HURT
	]
	
	no_flip = false
	
	for state in no_flipping:
		if(new_state == state):
			no_flip = true
			break
	
	# Set state specific parameters.
	match new_state:
		states.RESET:
			jumps_left = max_jumps
			
		states.BEAMIN:
			beam_y_pos = global_position.y
			global_position.y = gw.active_section.limit_top - 12
			$CollisionShape2D.disabled = true
		
		states.APPEARA:
			state_name = "APPEAR"
			global_position.y = beam_y_pos
			$CollisionShape2D.disabled = false
		
		states.JUMP:
			if(jump_tap): velocity.y = jump_str
			pass
	
	if($AnimationPlayer.has_animation(state_name)):
		$AnimationPlayer.play(state_name)

func exit_state(old_state: states, new_state: states) -> void:
	pass

func set_state(new_state: states) -> void:
	previous_state = current_state
	current_state = new_state
	
	ticker = 0
	
	exit_state(previous_state, current_state)
	enter_state(current_state, previous_state)

func _on_anim_done(anim_name: StringName) -> void:
	print("Animation ",anim_name," complete")
	match anim_name:
		"APPEAR":
			set_state(states.IDLE)
		
		"LILSTEP":
			if(dir_hold.x == 0):
				set_state(states.IDLE)
			else:
				set_state(states.RUN)
#enum states {
	#NULL,
	#RESET,
	#TOPSCREEN,
	#BEAMIN,
	#BEAMOUT,
	#APPEAR,
	#LEAVE,
	#IDLE,
	#LILSTEP,
	#RUN,
	#JUMP,
	#CLIMB,
	#TOP,
	#SLIDE,
	#HURT,
	#IDLESHOT,
	#RUNSHOT,
	#JUMPSHOT,
	#CLIMBSHOT,
	#IDLETHROW,
	#JUMPTHROW,
	#CLIMBTHROW
#}
#
#var no_flip_states := [ # These states will trigger the no_flip flag
		#states.NULL,
		#states.RESET,
		#states.TOPSCREEN,
		#states.BEAMIN,
		#states.BEAMOUT,
		#states.APPEAR,
		#states.LEAVE,
		#states.CLIMB,
		#states.TOP
	#]
#
#var current_state: states = states.NULL
#var previous_state: states = states.NULL
#
#func _ready() -> void:
	#im = get_node("/root/im")
	#gw = get_tree().get_first_node_in_group("GameWorld")
	#_set_state(states.RESET)
#
#func _process(delta: float) -> void:
	#if $Sprite2D.flip_h != current_flip: $Sprite2D.flip_h = current_flip
#
#func _physics_process(delta: float) -> void:
	#if current_state != states.NULL:
		#_state_logic(delta)
		#var t: states = _get_transition(delta)
		#if t != states.NULL:
			#_set_state(t)
#
#func _state_logic(delta: float) -> void:
	#if !no_flip: 
		## Flip the character sprite if needed.
		#if im.get_x_dir() == -1: current_flip = true
		#if im.get_x_dir() == 1: current_flip = false
	#
	#match current_state: # Apply gravity to the following states.
		#states.BEAMIN, states.BEAMOUT, states.IDLE, states.LILSTEP, states.RUN, states.JUMP, states.SLIDE, states.HURT, states.IDLESHOT, states.RUNSHOT, states.JUMPSHOT, states.IDLETHROW, states.JUMPTHROW:
			#apply_gravity(delta)
	#
	#match current_state: # Apply horizontal movement to the following states.
		#states.IDLE, states.RUN, states.JUMP, states.SLIDE, states.IDLESHOT, states.RUNSHOT, states.JUMPSHOT, states.JUMPTHROW:
			#apply_horizontal(delta)
		#
	#match current_state: # Halt horizontal movement to the following states.
		#states.IDLETHROW, states.LILSTEP, states.CLIMB, states.TOP, states.CLIMBSHOT, states.CLIMBTHROW:
			#if velocity.x != 0: velocity.x = 0
		#
	#match current_state: # Individual state functions and checks.
		#states.BEAMIN:
			#var dist: float = abs(global_position.y - spawn_y_pos)
			##Re-enable the hitbox so the player can land without issue.
			#if dist <= 20 && $CollisionShape2D.disabled: $CollisionShape2D.disabled = false
		#
		#states.JUMP:
			#if velocity.y < -2 && im.is_action_released("a"): velocity.y = -2
	#
	## Move the player.
	#move_and_slide()
	## Prevent the player from moving offscreen.
	#if gw.active_section != null: global_position.x = clamp(global_position.x, gw.active_section.x_clamp_low, gw.active_section.x_clamp_high)
#
#func _get_transition(delta: float) -> states:
	#match current_state:
		#states.RESET:
			#if global_position != Vector2.ZERO && gw.active_section != null: return states.TOPSCREEN
		#
		#states.TOPSCREEN:
			#if gw.current_state == GameWorld.states.RUN: return states.BEAMIN
		#
		#states.BEAMIN:
			#if is_on_floor(): return states.APPEAR
		#
		#states.IDLE:
			## If the player presses the jump button, jump
			#if im.is_action_pressed("a") && jumps_left > 0 || !is_on_floor(): return states.JUMP
			## If the player presses a direction, start the walk cycle.
			#if im.get_x_dir() != 0: return states.LILSTEP
		#
		#states.RUN:
			## If the player presses the jump button, jump
			#if im.is_action_pressed("a") && jumps_left > 0 || !is_on_floor(): return states.JUMP
			## If the player stops moving, return to idle.
			#if im.get_x_dir() == 0: return states.LILSTEP
			#
		#states.JUMP:
			## Check to see if the player has landed.
			#if is_on_floor() && im.get_x_dir() == 0: return states.IDLE
			#if is_on_floor() && im.get_x_dir() != 0: return states.RUN
	#return states.NULL
#
#func _enter_state(new_state: states, old_state: states) -> void:
	#no_flip = new_state in no_flip_states # Set the no_flip flag
	#
	#match new_state:
		#states.RESET:
			#jumps_left = max_jumps
			#
		#states.TOPSCREEN:
			## Set the player's position above the play field for the teleport animation.
			#global_position.y = gw.active_section.limit_top - 12
			#$CollisionShape2D.disabled = true # Disable the hit bos so Rock can move through obstacles if necessary
			#
		#states.JUMP:
			#velocity.y = jump_str
			#jumps_left -= 1
#
	## Grab the state name for the animation player.
	#var state_name: String = ""
	#for stname in states.keys():
		#if states[stname] == current_state: state_name = stname;
		#
	#if $AnimationPlayer.has_animation(state_name): $AnimationPlayer.play(state_name)
	#
#
#func _exit_state(old_state: states, new_state: states) -> void:
	#match old_state:
		#states.JUMP:
			#jumps_left = max_jumps
#
#func _set_state(new_state: states) -> void:
	#previous_state = current_state
	#current_state = new_state
	#
	#for stname in states.keys():
		#if states[stname] == current_state: print(name,", is now in state: ",stname);
	#
	#ticker = 0
	#
	#_exit_state(previous_state, current_state)
	#_enter_state(current_state, previous_state)
#
#
#func _on_anim_done(anim_name: StringName) -> void:
	#match anim_name:
		#"APPEAR":
			#_set_state(states.IDLE)
		#
		#"LILSTEP":
			#if im.get_x_dir() != 0: _set_state(states.RUN)
			#else: _set_state(states.IDLE)
