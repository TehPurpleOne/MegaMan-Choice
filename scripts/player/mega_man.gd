extends "res://scripts/player/player.gd"

class_name MegaMan

enum states {
	NULL,
	RESET,
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
	HURT
}

var current_state: states = states.NULL
var previous_state: states = states.NULL
