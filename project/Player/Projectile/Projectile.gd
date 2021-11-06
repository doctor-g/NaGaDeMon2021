extends KinematicBody2D

const _Orb := preload("res://Player/Orb/Orb.tscn")

export var speed := 350

var direction := Vector2.ZERO

func _physics_process(_delta):
	# warning-ignore:return_value_discarded
	move_and_slide(direction * speed, Vector2.UP)
	for i in range(0,get_slide_count()):
			var collision := get_slide_collision(i)
			if collision.collider.is_in_group("enemies"):
				var enemy : KinematicBody2D = collision.collider
				var orb : KinematicBody2D = _Orb.instance()
				orb.set_as_toplevel(true)
				orb.global_position = collision.position
				get_parent().add_child(orb)
				orb.capture(enemy)
				queue_free()
	
	if is_on_wall():
		queue_free()


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
