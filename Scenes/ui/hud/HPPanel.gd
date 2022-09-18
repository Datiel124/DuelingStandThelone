extends Panel

onready var hp_bar = $'%HpBar'
onready var shield_bar = $'%ShieldBar'


func set_hp(old, new):
	hp_bar.value = new
	hp_bar.modulate = lerp(Color.red, Color.green, new / 100)


func set_shield(old, new):
	shield_bar.value = new
	if new <= 0:
		shield_fadeout()
	else:
		shield_fadein()

func shield_fadeout():
	var s_icon = $Margin/valign/shieldmeter/icon
	var fadetween = get_tree().create_tween()
	fadetween = get_tree().create_tween()
	fadetween.set_parallel(true)
	fadetween.set_ease(Tween.EASE_OUT)
	fadetween.set_trans(Tween.TRANS_CIRC)
	fadetween.tween_property(s_icon, "modulate", Color.dimgray, 0.6)
	fadetween.set_ease(Tween.EASE_IN_OUT)
	fadetween.set_trans(Tween.TRANS_BACK)
	fadetween.tween_property(s_icon, "rect_scale", Vector2.ONE * 1.0, 0.25)
	fadetween.play()

func shield_fadein():
	var s_icon = $Margin/valign/shieldmeter/icon
	if s_icon.modulate == Color.dimgray:
		var fadetween = get_tree().create_tween()
		fadetween.set_parallel(true)
		fadetween.set_ease(Tween.EASE_OUT)
		fadetween.set_trans(Tween.TRANS_CIRC)
		fadetween.tween_property(s_icon, "modulate", Color('00dbff'), 0.75)
		fadetween.set_ease(Tween.EASE_IN_OUT)
		fadetween.set_trans(Tween.TRANS_BACK)
		fadetween.tween_property(s_icon, "rect_scale", Vector2.ONE * 1.5, 0.4)
		fadetween.play()
