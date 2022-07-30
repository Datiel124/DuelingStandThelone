extends Spatial

class_name Weapon

onready var anim_player = $AnimationPlayer

export var damage = 5
export var _range = 8000

onready var b_hole = preload('res://Scenes/entities/BulletHole.tscn')
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

func shoot(id : int = -1):
	print("Shot fired by " + str(id) + " rpc called by " + str(get_tree().get_rpc_sender_id()))
	#If called on server- calculate bullet trajectory (raycast), and calculate damage.
	#If called on client- do the visuals of the shot.
	var startpos = $MeshInstance/MuzzlePoint.global_transform.origin
	var newray = $RayCast.duplicate()
	$RayCast.add_child(newray)
	newray.global_transform.origin = startpos
	newray.cast_to = Vector3(0, 0, -_range)
	newray.force_raycast_update()
	var missposition = newray.global_transform.basis.z * -_range
	var endpos = newray.get_collision_point() if newray.is_colliding() else missposition
	if !get_tree().is_network_server():
		#If client...
		#display the visuals of the shot.
		renderShot(startpos, endpos)
	else:
		if get_tree().get_network_connected_peers().size() > 0:
			rpc_id(1, "calculateDamage" , startpos, endpos)
	#Delete newray. Isn't needed anymore.
	newray.queue_free()

remote func renderShot(startpos : Vector3, endpos : Vector3) -> void:
	#Convert start/end to a direction.
	$AnimationPlayer.stop()
	$AnimationPlayer.play('BaseShoot')
	var dir = startpos.direction_to(endpos)
	
	#Create a raycast. 
	var newray = RayCast.new()
	newray.global_transform.origin = startpos
	newray.cast_to = -_range * dir
	$RayCast.add_child(newray)
	newray.force_raycast_update()
	var missposition = newray.global_transform.basis.z * -_range
	pass

#The 'puppet' key word means the owner of this node cannot call this function. It must be called externally.
puppet func createBulletHole():
	pass

puppet func calculateDamage(startpos : Vector3, endpos : Vector3) -> void:
	#Calculate whether or not the raycast sent by the client actually hits an enemy.
	#In order to do this, we need to re-do the ray casting, so we need to convert startpos and endpos to a startpos and direction.
	#Then, cast the ray, and then, get collisions, check for players, etc.
	if !get_tree().is_network_server():
		#Only the server should be calculating damage.
		return
	#Convert start/end to a direction.
	var dir = startpos.direction_to(endpos)
	
	#Create a raycast. 
	var newray = RayCast.new()
	newray.global_transform.origin = startpos
	newray.cast_to = -_range * dir
	$RayCast.add_child(newray)
	newray.force_raycast_update()
	var missposition = newray.global_transform.basis.z * -_range
	
	#Check for collisions within the raycast.
	if newray.is_colliding():
		var hitobj = newray.get_collider()
		if hitobj is Player || hitobj.has_method("Damage"):
			#Broadcast to everyone that the player is getting hit, and is taking damage.
			hitobj.rpc("Damage", damage)
			#Do it on the server so the health is known.
			hitobj.Damage(damage)
		else:
			if hitobj is PhysicsBody:
				#Spawn a bullet hole at the destination position pointing away from the collision normal.
				rpc_unreliable("spawnBulletHole", endpos, newray.get_collision_normal())
	pass

func spawnBulletHole(pos, normal):
	pass
