@tool
extends Node2D

class_name Section

var active: bool = false

var limit_top: int
var limit_bottom: int
var limit_left: int
var limit_right: int

var x_clamp_low: float
var x_clamp_high: float

var transition_dir: Vector2 = Vector2.ZERO

var rect_pos: Vector2i
var tilemap_size: Vector2i = Vector2.ZERO

@export var seal_previous_section: bool = false;

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	limit_top = global_position.y
	limit_bottom = global_position.y + tilemap_size.y
	limit_left = global_position.x
	limit_right = global_position.x + tilemap_size.x
	
	x_clamp_low = limit_left + 6
	x_clamp_high = limit_right - 6
	
	_toggle_graphics(false)
	
func _on_rooms_changed() -> void:
	if !is_inside_tree():
		return
		
	var used_rect: Rect2 = $Rooms.get_used_rect()
	tilemap_size = used_rect.size as Vector2i * $Rooms.tile_set.tile_size
	rect_pos = used_rect.position as Vector2i * $Rooms.tile_set.tile_size
	var center_x: float = (used_rect.position.x + used_rect.size.x / 2.0) * $Rooms.tile_set.tile_size.x
	var center_y: float = (used_rect.position.y + used_rect.size.y / 2.0) * $Rooms.tile_set.tile_size.y
	
	$Trigger.position = Vector2(center_x, center_y)
	$Trigger/Box.shape.size = tilemap_size
	$Seal.position = Vector2(center_x, center_y)
	$Seal/Box.shape.size = tilemap_size
	
	$DebugRect.queue_redraw()

func _on_player_entered(body: Node2D) -> void:
	# Whenever the player enters a section, run some checks, and if necessary, transition the screen.
	if active:
		print("Current section is already active.")
		return
	
	var p: Player = body
	var p_pos: Vector2 = Vector2(p.global_position.x - global_position.x, p.global_position.y - global_position.y)
	
	print("Player has entered new section ",name," at position ",p_pos)
	
	var cam: GameCamera = get_tree().get_nodes_in_group("GameCamera")[0] #Grab the camera.
	
	# Prevent the script from going on if the camera is inactive.
	if cam.active_section != null && cam.current_state != cam.states.ACTIVE && cam.current_state != cam.states.SNAP:
		print("No need to update the camera.")
		return
	
	# Check to see if an active section has been set, or if the camera is in SNAP mode. Run functions accordingly.
	if cam.active_section == null || cam.current_state == cam.states.SNAP:
		print("No previous active section or camera is set to SNAP")
		_toggle_graphics(true)
		cam._set_active_section(self)
		return
	else:
		print("Beginning transition check.")
		_update_direction(cam.active_section)
	
	# If the transition direction is zero, stop function.
	if transition_dir == Vector2.ZERO:
		print("Transition direction is zero. Abandoning function.")
		return
	
	# If the transition direction is up and the player is not climbing, stop function.
	if transition_dir == Vector2.UP && p.current_state == p.states.CLIMB:
		print("Transition up can only be done while climbing. Abandining function.")
		return
	
	cam._transition(self)

func _update_direction(previous_section: Section) -> void:
	# This function will determine which direction the camera will pan during a transition.
	transition_dir = Vector2.ZERO
	var is_vertical: bool = true
	
	if limit_top == previous_section.limit_top && limit_bottom == previous_section.limit_bottom:
		is_vertical = false
	
	match is_vertical:
		true:
			var y: bool = global_position.y < previous_section.global_position.y
			
			match y:
				true:
					transition_dir = Vector2.UP
					print("Transition direction set to up.")
				false:
					transition_dir = Vector2.DOWN
					print("Transition direction set to down.")
		false:
			var x: bool = global_position.x < previous_section.global_position.x
			
			match x:
				true:
					transition_dir = Vector2.LEFT
					print("Transition direction set to left.")
				false:
					transition_dir = Vector2.RIGHT
					print("Transition direction set to right.")

func _set_seal(value: bool) -> void:
	# If seal_previous_section is true, this will cut off the player from returning to the last section.
	$Area2D/CollisionShape2D.disabled = value
	$StaticBody2D/CollisionShape2D.disabled = !value
	
	print("Previous area, ",name,", has been sealed!")
	
func _toggle_graphics(value: bool) -> void:
	var hide_check: bool = !$Rooms.visible && !$Collision.visible && !$Graphic.visible
	var tiles_check: bool = $Graphic/Tiles.tile_set != null || $Graphic/Tiles.get_used_cells().size() > 0
	
	if hide_check && value:
		match tiles_check:
			true:
				$Graphic.show()
			
			false:
				$Rooms.show()
				$Collision.show()
	
	if !value:
		$Rooms.hide()
		$Collision.hide()
		$Graphic.hide()
