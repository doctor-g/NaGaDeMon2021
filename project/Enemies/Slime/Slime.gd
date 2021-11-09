extends KinematicBody2D

export var speed := 100

var captured := false

var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _velocity := Vector2.ZERO
var _moving_right := false

onready var _sprite := $AnimatedSprite

func _ready():
	# The slime defaults to facing left
	_velocity.x = -speed


func _physics_process(_delta):
	if not captured:
		_velocity.y += _gravity
		_velocity = move_and_slide(_velocity, Vector2.UP)
		if is_on_wall():
			_moving_right = not _moving_right
			_velocity.x = speed if _moving_right else -speed
		_sprite.flip_h = _moving_right


# Damage the enemy, with the damage coming from the given source (pawn)
func damage(source)->void:
	var points = 100
	source.score += points
	
	# Make and show the popup
	var points_popup = preload("res://Enemies/PointsPopup.tscn").instance()
	points_popup.color = source.color
	points_popup.points = points
	get_tree().current_scene.add_child(points_popup)
	points_popup.set_as_toplevel(true)
	points_popup.position = global_position
	print("Added popup at %s" % str(points_popup.position))
	
	queue_free()
