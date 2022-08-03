extends Spatial
class_name ProjectileWeapon, 'res://DEV/class_icons/gunicon.png'

export(PackedScene) var projectile
export var projectileSpeed : float = 25.0;

func shoot(event : InputEvent, id : int = -1) -> void:
	print("Projectile Shot fired by " + str(id) + " rpc called by " + str(get_tree().get_rpc_sender_id()))
	#If called on server- calculate bullet trajectory (raycast), and calculate damage.
	#If called on client- do the visuals of the shot.
	
	if !get_tree().is_network_server():
		#client fired, tell server to spawn stuff
		if get_tree().get_network_connected_peers().size() > 0:
			rpc_id(1, "createProjectile")
		else:
			createProjectile()
	else:
		if is_network_master():
			#server is playing
			rpc("createProjectile")

func createProjectile():
	var newproj : Projectile = projectile.instance()
	$instances.add_child(newproj)
	newproj.global_transform = $MuzzlePoint.global_transform
	newproj.Velocity = Vector3.UP * 50
