extends AnimatedSprite2D

class_name OneShot

@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = 0.0
@export var use_player_flip: bool = false

var cam: GameCamera
var sprite_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	cam = get_tree().get_nodes_in_group("GameCamera")[0]
	sprite_size = sprite_frames.get_frame_texture("default", 0).get_size()
	
	if use_player_flip:
		var get_player: Player = get_tree().get_nodes_in_group("Player")[0]
		flip_h = get_player.current_flip

func _physics_process(delta: float) -> void:
	if speed > 0:
		global_position += direction * speed
		
		var cam_top_left: Vector2 = (cam.get_screen_center_position() - Vector2(192, 112)) - sprite_size
		var cam_rect_size: Vector2 = Vector2(384, 224) + (sprite_size * 2)
		var camera_bounds: Rect2 = Rect2(cam_top_left, cam_rect_size)
		
		if !camera_bounds.has_point(global_position): queue_free()

func _on_animation_finished() -> void:
	queue_free()
