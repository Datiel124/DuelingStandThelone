extends Spatial

class_name Weapon

onready var anim_player = $AnimationPlayer

export var damage = 5
export var reloadTime = 0.8

onready var b_hole = preload("res://Scenes/entities/BulletHole.tscn")

remote func shoot():
	var particles = get_node("MeshInstance/MuzzlePoint/Particles").duplicate()
	
	particles.emitting = true
	
	$MeshInstance/MuzzlePoint.add_child(particles)
	
	particles.transform = $MeshInstance/MuzzlePoint/Particles.transform
	get_tree().create_timer(5).connect("timeout", particles, "queue_free")
	
	if ! anim_player.is_playing():
		anim_player.play("BaseShoot")
	
	var camera_transform = get_viewport().get_camera().global_transform
	var ray = RayCast.new()
	
	get_tree().get_root().add_child(ray)
	
	ray.global_transform = camera_transform
	ray.cast_to = Vector3.FORWARD * 90
	ray.exclude_parent = true
	ray.force_raycast_update()
	
	var collider = ray.get_collider()
	
	#Bullet Hole Creation
	if collider is CSGCombiner:
		var normal = ray.get_collision_normal()
		var bullet = b_hole.instance()
		get_tree().get_root().add_child(bullet)
		bullet.global_transform.origin = ray.get_collision_point()
		if normal.is_equal_approx(Vector3.UP):
			bullet.rotation_degrees.x = 90
		elif normal.is_equal_approx(Vector3.DOWN):
			bullet.rotation_degrees.x = -90
		else:
			bullet.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3.UP)
	
	if collider is KinematicBody:
		if collider.has_method("Damage"):
			collider.Damage(damage)
			#if is_network_master() or !get_tree().network_peer:
				#collider.rpc("Damage",damage)
				#collider.Damage(damage)
	ray.queue_free()

func reload():
	pass
