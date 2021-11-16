extends "Level.gd"

func _run():
	var Slime := preload("res://Enemies/Slime/Slime.tscn")
	yield(get_tree().create_timer(1.0), "timeout")
	
	_spawners[0].spawn(Slime, true)
	_spawners[1].spawn(Slime, false)
	yield(get_tree().create_timer(3.0), "timeout")
	
	_spawners[0].spawn(Slime, true)
	_spawners[1].spawn(Slime, false)
	
	_spawning_complete = true
	for spawner in _spawners:
		spawner.expire()
