extends Spatial

class_name Weapon

onready var anim_player = $AnimationPlayer

export var damage = 5
export var reloadTime = 0.8
export var Ammo = 5 setget setammo
export var MagSize = 10

enum _AmmoType {Pistol, Shotgun}
export(_AmmoType) var AmmoType = _AmmoType.Pistol


func setammo(amount):
	Ammo = clamp(amount, 0, MagSize)

remote func shoot():
	
	var particles = get_node("MeshInstance/Particles").duplicate()
	
	particles.emitting = true
	
	$MeshInstance.add_child(particles)
	
	particles.transform = $MeshInstance/Particles.transform
	get_tree().create_timer(5).connect("timeout", particles, "queue_free")
	
	if ! anim_player.is_playing():
		anim_player.play("BaseShoot")
	
	var camera_transform = get_viewport().get_camera().global_transform
	var ray = RayCast.new()
	
	add_child(ray)
	
	ray.global_transform = camera_transform
	ray.cast_to = Vector3.FORWARD * 9000
	ray.force_raycast_update()
	
	var collider = ray.get_collider()
	print(collider)
	
	if collider is KinematicBody:
		if collider.has_method("Damage"):
			collider.Damage(damage)
			#if is_network_master() or !get_tree().network_peer:
				#collider.rpc("Damage",damage)
				#collider.Damage(damage)
	
	yield(get_tree(), "idle_frame")
	ray.queue_free()
	
func reload():
	pass
