extends Spatial

class_name Weapon

onready var anim_player = $AnimationPlayer

export(String) var WeaponName = "test_weapon"
export var damage = 5
export var _range = 8000

onready var b_hole = preload('res://Scenes/entities/BulletHole.tscn')
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

func shoot(id : int = -1) -> void:
	print("Shot fired by " + str(id) + " rpc called by " + str(get_tree().get_rpc_sender_id()))
	#If called on server- calculate bullet trajectory (raycast), and calculate damage.
	#If called on client- do the visuals of the shot.
	var calc = getShotRay()
	
	if !get_tree().is_network_server():
		#If client...
		#display the visuals of the shot.
		renderShot(calc.startpos, calc.endpos)
		if get_tree().get_network_connected_peers().size() > 0:
			#Tell the server to calculate damage.
			rpc_id(1, "calculateDamage", calc.startpos, calc.endpos)
		else:
			#Singleplayer. Calculate damage yourself.
			calculateDamage(calc.startpos, calc.endpos)
	else:
		#If server...
		if is_network_master():
			#non-dedicated peer-to-peer compat
			renderShot(calc.startpos, calc.endpos)

func getShotRay(direction : Vector3 = Vector3(0, 0, -1)) -> Dictionary:
	var startpos = get_viewport().get_camera().global_transform.origin
	var newray = $RayCast.duplicate()
	get_tree().get_root().add_child(newray)
	newray.global_transform = get_viewport().get_camera().global_transform
	newray.cast_to = direction.normalized() * _range
	newray.force_raycast_update()
	var missposition = newray.global_transform.basis.z * -_range
	var endpos = newray.get_collision_point() if newray.is_colliding() else missposition
	newray.queue_free()
	return {"startpos":startpos, "endpos":endpos}

remote func renderShot(startpos : Vector3, endpos : Vector3) -> void:
	#Convert start/end to a direction.
	$AnimationPlayer.stop()
	$AnimationPlayer.play('BaseShoot')
	var dir = startpos.direction_to(endpos)
	
	#Create a raycast. 
	var newray = RayCast.new()
	$RayCast.add_child(newray)
	newray.global_transform.origin = startpos
	newray.cast_to = -_range * dir
	newray.force_raycast_update()
	var missposition = newray.global_transform.basis.z * -_range
	pass

#The 'puppet' key word means the owner of this node cannot call this function. It must be called externally.
remote func createBulletHole(pos, looktgt):
	print("smack that at " + str(pos) + str(looktgt))
	var newb : Spatial = b_hole.instance()
	get_tree().get_root().add_child(newb)
	newb.global_transform.origin = pos
	newb.look_at(looktgt, Vector3.UP)
	pass

puppet func calculateDamage(startpos : Vector3, endpos : Vector3) -> void:
	#Calculate whether or not the raycast sent by the client actually hits an enemy.
	#In order to do this, we need to re-do the ray casting, so we need to convert startpos and endpos to a startpos and direction.
	#Then, cast the ray, and then, get collisions, check for players, etc.
	#Convert start/end to a direction.
	var dir = startpos.direction_to(endpos)
	
	#Create a raycast. 
	var newray = RayCast.new()
	$RayCast.add_child(newray)
	newray.global_transform.origin = startpos
	newray.cast_to = -_range * dir
	newray.force_raycast_update()
	var missposition = newray.global_transform.basis.z * -_range
	
	#Check for collisions within the raycast.
	if newray.is_colliding():
		var hitobj = newray.get_collider()
		if hitobj is Player || hitobj.has_method("Damage"):
			#Broadcast to everyone that the player is getting hit, and is taking damage.
			hitobj.rpc("Damage", damage)
			#Do it on the server so the health is known. yea
			hitobj.Damage(damage)
		else:
			print("Hit a thing")
			#Spawn a bullet hole at the destination position pointing away from the collision normal.
			#Unreliable cuz idk how many bullet holes will be made, probably too many, doesnt matter so much
			rpc_unreliable("createBulletHole", endpos, (endpos + newray.get_collision_normal()))
			if is_network_master():
				#compat
				createBulletHole(endpos, (endpos + newray.get_collision_normal()))
	pass
