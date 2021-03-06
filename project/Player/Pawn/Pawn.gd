class_name Pawn
extends KinematicBody2D

# Emitted when the player is dead and the death animation is complete
signal dead

const _PROJECTILE := preload("res://Player/Projectile/Projectile.tscn")

export var speed := 250
export var jump_strength := 780
export var start_facing_right := true setget _set_start_facing_right

var player
var start_invincible := false
var index := 0 

var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _velocity := Vector2.ZERO
var _dead := false
var _dancing := false
var _action_prefix : String

onready var _sprite : AnimatedSprite = $SpriteContainer/PawnSprite
onready var _anim_player := $AnimationPlayer
onready var _projectile_spawn_point := $ProjectileLaunchPoint
onready var _damageable_area := $DamageableArea
onready var _invincibility_timer := $InvincibilityTimer
onready var _sprite_container := $SpriteContainer
onready var _shoot_sound := $ShootSound
onready var _jump_sound := $JumpSound

func _ready():
	assert(player!=null, "Player must be specified")
	
	_action_prefix = "p%d_" % (index + 1)
	$SpriteContainer/PawnSprite.index = index	
	
	# Reset the animation tracks, e.g. to undo the material animation
	# from teleporting out.
	_anim_player.play("RESET")

	if start_invincible:
		_invincibility_timer.start()
		_sprite.modulate = Color(1,1,1,0.4)
		_damageable_area.monitoring = false
		
	# If we're not starting invicible, it should be the start of the
	# round, so teleport in
	else:
		_anim_player.play("teleport-in")
		

func _physics_process(_delta):
	if _dead or _dancing:
		return
	
	_velocity.y += _gravity
	
	if Input.is_action_pressed(_action("duck")):
		_sprite.play("duck")
		_velocity.x = 0
		
		# Allow jumping down through tiles
		if Input.is_action_just_pressed(_action("jump")):
			# Note that for non-one-way tiles, the physics engine will
			# simply push the player back out of the collision, so we
			# do not need a raycast or anything here.
			position.y += 1
	else:
		_process_movement_input()
	
	var direction_x = _velocity.x
	_velocity = move_and_slide(_velocity, Vector2.UP)
	for i in range(0, get_slide_count()):
		var collision := get_slide_collision(i)
		if collision.collider.is_in_group("orbs"):
			collision.collider.kick(Vector2.RIGHT if direction_x>0 else Vector2.LEFT)


# Format a given action name with the current player's action prefix
func _action(name:String)->String:
	return _action_prefix + name


func _process_movement_input()->void:
	var direction := Input.get_action_strength(_action("move_right")) \
						 - Input.get_action_strength(_action("move_left"))
	_velocity.x = speed * direction
	if _velocity.x != 0:
		_sprite.flip_h = _velocity.x < 0
		if sign(_projectile_spawn_point.position.x) != sign(_velocity.x):
			_projectile_spawn_point.position.x *= -1
		
	if is_on_floor() and Input.is_action_just_pressed(_action("jump")):
		_velocity.y -= jump_strength
		_jump_sound.play()
	
	if not is_on_floor():
		_sprite.play("jump")
	else:
		_sprite.play("walk" if _velocity.x != 0 else "idle")
	
	if Input.is_action_just_pressed(_action("fire")):
		_shoot_sound.play()
		var projectile := _PROJECTILE.instance()
		projectile.player = player
		projectile.direction = Vector2.LEFT if _sprite.flip_h else Vector2.RIGHT
		projectile.position = _projectile_spawn_point.global_position
		get_parent().add_child(projectile)


# Play the hurt animation of the current sprite
func _play_hurt_animation():
	_sprite.play("hurt")
	

# Play the dance animation
func dance():
	_dancing = true
	_sprite.play("dance")
	yield(get_tree().create_timer(0.5), "timeout")
	_anim_player.play("teleport-out")
	

# Check if this pawn is in the state of playing its dying animation
func is_playing_death_animation()->bool:
	return _dead


# This is called when an enemy crosses into the damageable area of the player.
# The orb can also cross this line because the orb has to register collisions
# with the player, so it can be kicked. This should only happen if the orb
# is spawned too close to the player, and then the physics system jerks them
# apart.
func _on_DamageableArea_body_entered(body:Node2D):
	# Make sure it's an enemy and not the orb as described above.
	if body.is_in_group("enemies") or body.is_in_group("fireball"):
		_dead = true
		_sprite.stop()
		$StandingCollision.set_deferred("disabled", true)
		$DamageableArea/CollisionShape2D.set_deferred("disabled", true)
		_anim_player.play("dead")
		
		# If this is the last life lost by a player, they cannot earn any more
		# points
		if player.lives == 1:
			player.can_earn_points = false


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name=="dead":
		emit_signal("dead")
		queue_free()


func _on_InvincibilityTimer_timeout():
	_sprite.modulate = Color.white
	_damageable_area.monitoring = true
	

func _set_start_facing_right(value:bool)->void:
	start_facing_right = value
	_sprite.flip_h = not value
