extends Spatial

class_name Weapon

onready var anim_player = $AnimationPlayer

export var damage = 5

onready var b_hole = preload('res://Scenes/entities/BulletHole.tscn')
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

func shoot():
	print("pew")
