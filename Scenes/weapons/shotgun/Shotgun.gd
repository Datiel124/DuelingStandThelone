extends Weapon

func shoot(id : int = -1) -> void:
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
		if is_network_master():
			#non-dedicated peer-to-peer compat
			renderShot(startpos, endpos)
		if get_tree().get_network_connected_peers().size() > 0:
			rpc_id(1, "calculateDamage" , startpos, endpos)
	#Delete newray. Isn't needed anymore.
	newray.queue_free()
