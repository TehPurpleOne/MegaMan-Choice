extends CharacterBody2D

class_name Player

@export var gravity: float = 900 # How fast the player is pulled back to the ground.
@export var gravity_mod_default: float = 1 # Default gravity modifier. This is what gravity_mod will reset to.
@export var jump_str: float = -310 # How fast the player leaves the ground during a jump.
@export var max_y_vel: float = 500 # Maximum downward speed.
@export var max_jumps: int = 0 #How many times a player can jump before needing to land.
@export var run_speed: float = 82.5 #How fast the playr can run.
@export var climb_speed_mod: float = 0.9 # How fast the player can climb.
@export var x_speed_mod_default: float = 1 # Horizontal speed modifier default.
@export var acceleration: float = 0.8 # Speed of which the x modifier adjusts horizontal speed.
@export var dash_mod: float = 2 # Horizontal speed modifer for dashing/sliding.
@export var dash_dist: float = 24 # Frames the player will stay sliding without canceling.
@export var iframes_max: int = 60 # Number of frames the player is innulnerable to damage.
@export var sprite_sheet_frame_width: int = 0 # Number of frames in each row of the sprite sheet.

var current_flip: bool = false # This will handle sprite flipping.
var ladder_flip: bool = false # Ladders and sprite flipping is wierd in the NES games. Explanation below.
var no_flip: bool = false # If true, flipping cannot occur.
var ignore_jump_hold: bool = false # If true, the player cannot control the hieight of their jump. Useful for Rush Coil
@export var ice: bool = false # Ice flag. If true, the player will slide along the ground.
var shoot: bool = false # Player is shooting the buster
var throw: bool = false # Player has thrown a weapon or item
var weapon_id: int = 0 # Current weapon ID. This will be used to determine which weapon to fire and what color the player is.
var iframes: int = 0 # Invinsibility frames.
var jumps_left: int = 0 # Jumps left before the player must touch the ground.
var dash: int = 0 # Dash ticker. Handles when the player will exit a dash or slide.
var shot_delay: int = 0 # Shot delay. How long the shooting sprites remain on screen.
var base_frame: int = 0 # Base frame for the animation player.
var x_speed: float = 0 # Horizontal speed of the player.
var x_speed_mod: float = 1 # Horizontal speed modifier. The higher the value, the faster the player can move outside it's base speed.
var gravity_mod: float = 1 # Current gravity modifier. The higher the value, the faster the player falls.
var beam_y_pos: float = 0 # Needed to trigger the player's collision box after teleporting into the stage.
var ticker: int = 0 # A simple ticker that adds 1 to it's value every frame. Resets upon state change.
var spawn_y_pos: float = 0 # Saves the Y coordinate of where the current spawn point is.

# Player input
var dir_tap: Vector2 = Vector2.ZERO
var dir_hold: Vector2 = Vector2.ZERO
var jump_tap: bool = false
var jump_release: bool = false
var fire_tap: bool = false
var fire_held: bool = false
var fire_release: bool = false
var slide_tap: bool = false
var wpn_tap: bool = false

enum states { # Player state. Add/remove as needed.
	NULL,		# Player physics and animations will not process.
	RESET,		# Reset the player.
	BEAMIN,		# Set to the top of the screen and drop the player in.
	BEAMOUT,	# The player rises up until gone.
	APPEARA,	# Appear animation when starting a stage. This is divided into 2 due to some PCs having specific animations. (Bass)
	APPEARB,	# Appear animation ater using a teleporter.
	LEAVEA,		# Leave animation upon clearing a stage.
	LEAVEB,		# Leave animation when using a teleporter.
	IDLE,		# Standing still.
	LILSTEP,	# The little step before the player begins moving.
	RUN,		# Running
	JUMP,		# Jumping
	CLIMB,		# Climbing a ladder
	TOP,		# Climbing at the top of a ladder
	SLIDE,		# Sliding
	HURT,		# Damaged
	FALL		# Player fell down.
}

var current_state: states = states.NULL
var previous_state: states = states.NULL

enum secondary_state { # This will help swap the sprites between the normal poses and the secondary on the fly.
	NORMAL = 0,
	SHOOT = 1,
	THROW = 2
}

var im: InputManager
var gw: GameWorld
var p_sprite: Sprite2D

func input_manager() -> void:
	if(im.current_state == InputManager.states.PLAYER):
		# These will only respond to input whenever the input handler is in Player Mode.
		# When in any other mode, devs can control the player as necessary through code.
		dir_tap = Vector2(int(im.is_pressed("right")) - int(im.is_pressed("left")), int(im.is_pressed("down")) - int(im.is_pressed("up")))
		dir_hold = Vector2(int(im.is_held("right")) - int(im.is_held("left")), int(im.is_held("down")) - int(im.is_held("up")))
		
		jump_tap = im.is_pressed("a")
		jump_release = im.is_released("a")
		
		fire_tap = im.is_pressed("b")
		fire_release = im.is_released("b")
		
		slide_tap = im.is_held("down") && im.is_pressed("a")
	
	if(im.current_state == InputManager.states.PLAYER || im.current_state == InputManager.states.QUICKSWAP):
		fire_held = im.is_held("b") # Just in case a charge function is added.
		
		wpn_tap = im.is_pressed("select") # Allow the player to cycle through available weapons as a boss is doing its intro.

func set_palette(id: int) -> void:
	# This function will set the appropriate palette for the player.
	var sprite_material: Material = self.material
	sprite_material.set_shader_material("index", id)

func update_base_frame(frame: int) -> void:
	base_frame = frame

func sprite_offset() -> void:
	# This function will set the appropriate offset when drawing the player's sprite to denote firing or throwing.
	var secondary_offset: int = 0;
	
	# Figure which states are active.
	if(shoot):
		secondary_offset += int(secondary_state.SHOOT)
	if(throw):
		secondary_offset += int(secondary_state.THROW)
	
	# NOTE: The shoot and throw flags should never be set to true at the same time.
	p_sprite.frame = base_frame + (secondary_offset * sprite_sheet_frame_width)

func flip_state() -> void:
	if(!no_flip):
		#  Don't force a certain flip when hurt or fallen, but don't allow the player to swap directions either.
		if(current_state == states.HURT || current_state == states.FALL): return
		# Set the ladder flip. This will update depending on the direction held no matter what.
		if(dir_hold.x == -1):
			ladder_flip = true
		elif(dir_hold.x == 1):
			ladder_flip = false
		# When on the ladder and NOT attacking, the player is locked to a certain flip state. Otherwise, set the current_flip to match the ladder flip.
		if(current_state == states.CLIMB && !shoot && !throw || current_state == states.TOP && !shoot && !throw):
			current_flip = false
		else:
			current_flip = ladder_flip
	else:
		# Lock the flip states to false if no flipping is allowed.
		ladder_flip = false
		current_flip = false
	
	# Once the correct flip state is achieved, apply it to the sprite.
	p_sprite.flip_h = current_flip

func apply_y(delta: float) -> void:
	# Pull the player downward.
	velocity.y += (gravity * delta) * gravity_mod
	# Cap the player's Y speed so they don't get moving too fast.
	if(velocity.y > 500): velocity.y = 500

func stop_y() -> void:
	velocity.y = 0

func apply_x() -> void:
	if(ice && is_on_floor()):
		if(dir_hold.x != 0):
			# Check to see if the player is moving in the opposite direction.
			if(x_speed > 0 && dir_hold.x < 0 || x_speed < 0 && dir_hold.x > 0):
				# Double the deceleration when reversing direction.
				x_speed = move_toward(x_speed, dir_hold.x * run_speed, acceleration * 2)
			else:
				# Normal acceleration towards the desired direction.
				x_speed = move_toward(x_speed, dir_hold.x * run_speed, acceleration)
		else:
			# No direction held. Slow to a stop.
			x_speed = move_toward(x_speed, 0, acceleration)
	else:
		# No ice phsyics necessary.
		x_speed = run_speed * dir_hold.x
	
	if(dash > 2 && is_on_floor()):
		# If the player is sliding/dashing, overwrite the above for this movement instead.
		var dash_dir: float = 0
		if(current_flip):
			dash_dir = -1
		else:
			dash_dir = 1
			
		x_speed = run_speed * dash_dir
	
	velocity.x = x_speed * x_speed_mod

func stop_x() -> void:
	velocity.x = 0
