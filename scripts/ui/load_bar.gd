extends Control

class_name LoadBar

func _set_value(value: float) -> void:
	$TextureProgressBar.value = value;
