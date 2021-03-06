extends "res://Enemies/Slime/Slime.gd"

const _FIREBALL := preload("res://Enemies/Slime/Fireball.tscn")

# Strength of fireball launch
export var fireball_impulse := 400.0
# Rate of fire
export var fire_rate := 2.0
# Increase in rate of fire per difficulty level (percent)
export var fire_rate_increase := 0.33

var _fire_angle := Vector2.RIGHT.rotated(-PI/3)

onready var _fireball_timer := $FireballTimer
onready var _fireball_sound := $FireballSound

func _ready():
	_fireball_timer.wait_time = fire_rate - difficulty * fire_rate_increase
	_fireball_timer.start()


func _on_FireballTimer_timeout():
	_fireball_sound.play()
	var fireball : RigidBody2D = _FIREBALL.instance()
	get_parent().add_child(fireball)
	fireball.global_position = global_position
	fireball.set_as_toplevel(true)
	var angle := _fire_angle
	if direction.x < 0:
		angle.x *= -1
	fireball.apply_impulse(Vector2.ZERO, angle * fireball_impulse)


func _set_captured(value:bool)->void:
	._set_captured(value)
	if value:
		_fireball_timer.stop()
	else:
		_fireball_timer.start()
