extends Spatial

class_name Weapon

onready var anim_player = $AnimationPlayer

export var damage = 5

onready var b_hole = preload("res://Scenes/entities/BulletHole.tscn")
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

remote func shoot():
	
	#Muzzle Flash
	var muzzle_flash = get_node("MeshInstance/MuzzlePoint/Particles").duplicate()
	muzzle_flash.emitting = true
	$MeshInstance/MuzzlePoint.add_child(muzzle_flash)
	muzzle_flash.transform = $MeshInstance/MuzzlePoint/Particles.transform
	get_tree().create_timer(5).connect("timeout", muzzle_flash, "queue_free")
	
	#Animation
	anim_player.play("BaseShoot")
	
	#Bullet Ray
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
			bullet.rotation_degrees.z = randi()
			
	#Spark Creation
	if collider is CollisionShape:
		if collider.is_in_group("Metal"):
			var normal = ray.get_collision_normal()
			var _spark = spark.instance()
			print("made spark")
			get_tree().get_root().add_child(_spark)
			if normal.is_equal_approx(Vector3.UP):
				_spark.rotation_degrees.x = 90
			elif normal.is_equal_approx(Vector3.DOWN):
				_spark.rotation_degrees.x = -90
			else:
				_spark.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3.UP)
	
	#Ray Collision Checks
	if collider is KinematicBody:
		if collider.has_method("Damage"):
			collider.Damage(damage)
			#if is_network_master() or !get_tree().network_peer:
				#collider.rpc("Damage",damage)
				#collider.Damage(damage)
				
	#Delete Raycast
	ray.queue_free()

func reload():
	pass
