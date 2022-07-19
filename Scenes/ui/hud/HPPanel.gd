extends Panel

func set_hp(old, new):
	$Margin/Hbox/HpBar.value = new
	$Margin/Hbox/HpBar.modulate = lerp(Color.red, Color.green, new / 100)
