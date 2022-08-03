extends Spatial
class_name Weapon, 'res://DEV/class_icons/gunicon.png'

onready var anim_player = $AnimationPlayer

export(String) var WeaponName = "test_weapon"
export(PackedScene) var projectile
export var fullauto : bool = false 
export var cooldown = 0.2 setget setCooldown
func setCooldown(new):
	cooldown = new
	$cooldown.wait_time = new
export var bullet_speed = 20.0;

#overrides bullet damage and explosion on spawn if available
export var override_dmg = 0.0;
export(PackedScene) var override_explosion;

onready var b_hole = preload('res://Scenes/entities/BulletHole.tscn')
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

func _ready() -> void:
	$cooldown.wait_time = cooldown

var shooting : bool = false
puppet var canShoot : bool = true
func _InputFromPlayer(event:InputEvent) -> void:
	if !is_network_master():
		printerr("invalid Weapon access")
		return
	if fullauto:
		if event.is_action_released('fire') || !canShoot:
			#set shooting to false to disable autofire
			shooting = false
			$cooldown.disconnect('timeout', self, "rpc_id")
			$cooldown.disconnect('timeout', self, "fire")
	if $cooldown.time_left <= 0 && canShoot:
		if fullauto:
			if event.is_action_pressed('fire'):
				#set shooting to true to enable autofire
				shooting = true
				rpc_id(1, "fire")
				fire()
				$cooldown.connect('timeout', self, "rpc_id", [1, "fire"])
				$cooldown.connect('timeout', self, "fire")
		else:
			if event.is_action_pressed('fire'):
				rpc_id(1, "fire")
				fire()

signal spawnABullet(bullet)
remote func fire():
	#When called by the client, it should rpc to the server. The server should then spawn the projectile.
	#Check if you are the server.
	if !get_tree().is_network_server():
		#Clients- Play the animations. Do nothing else.
		if is_network_master():
			$cooldown.start(cooldown)
		$sounds/shoot.stream = $sounds.shoot_sounds[randi()%$sounds.shoot_sounds.size()]
		$sounds/shoot.play()
		anim_player.stop()
		anim_player.play("BaseShoot")
		return

#SERVER STUFF
	if projectile:
		var newproj :Projectile= projectile.instance()
		newproj.name = filename + str(randi())
		#Spawn the bullet locally, on the server.
		emit_signal('spawnABullet', newproj)
		#Tell everyone to spawn this bullet.
		rpc("emit_signal", 'spawnABullet', newproj)
		newproj.global_transform.origin = $MeshInstance/MuzzlePoint.global_transform.origin
		newproj.Velocity = Vector3.FORWARD * bullet_speed
		newproj.shooter = get_tree().get_rpc_sender_id()
		if override_dmg:
			newproj.damage = override_dmg
		if override_explosion:
			newproj.Explosion = override_explosion

remote func createProjectile():
	pass

