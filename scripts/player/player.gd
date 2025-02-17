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
@export var x_mod_adjust: float = 0.01 # Speed of which the x modifier adjusts horizontal speed.
@export var dash_mod: float = 2 # Horizontal speed modifer for dashing/sliding.
@export var dash_dist: float = 24 # Frames the player will stay sliding without canceling.
@export var iframes_max: int = 60 # Number of frames the player is innulnerable to damage.

var current_flip: bool = false # This will handle sprite flipping.
var no_flip: bool = false # If true, flipping cannot occur.
var weapon_id: int = 0 # Current weapon ID. This will be used to determine which weapon to fire and what color the player is.
var iframes: int = 0 # Invinsibility frames.
var jumps_left: int = 0 # Jumps left before the player must touch the ground.
var dash: int = 0 # Dash ticker. Handles when the player will exit a dash or slide.
var shot_delay: int = 0 # Shot delay. How long the shooting sprites remain on screen.
var x_speed: float = 0 # Horizontal speed of the player.
var x_speed_mod: float = 1 # Horizontal speed modifier. The higher the value, the faster the player can move outside it's base speed.
var gravity_mod: float = 1 # Current gravity modifier. The higher the value, the faster the player falls.
var beam_y_pos: float = 0 # Needed to trigger the player's collision box after teleporting into the stage.
var ticker: int = 0 # A simple ticker that adds 1 to it's value every frame. Resets upon state change.
var spawn_y_pos: float = 0 # Saves the Y coordinate of where the current spawn point is.

var im: InputManager
var gw: GameWorld

func apply_gravity(delta: float) -> void:
	# Pull the player downward.
	velocity.y += (gravity * delta) * gravity_mod
	# Cap the player's Y speed so they don't get moving too fast.
	velocity.y = clamp(velocity.y, -max_y_vel, max_y_vel)

func apply_horizontal(delta: float) -> void:
	# Update for ice physics
	x_speed = (run_speed * x_speed_mod) * im.get_x_dir()
	velocity.x = x_speed
