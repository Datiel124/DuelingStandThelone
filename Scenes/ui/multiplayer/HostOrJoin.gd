extends PopupPanel

func _on_HOST_pressed() -> void:
	hide()
	NetworkLobby.my_info.username = $Control/usernamefield.text if checkValidUser() else generateRandomName()
	$HOSTdialogue.popup()
	pass # Replace with function body.

func _on_JOIN_pressed() -> void:
	hide()
	NetworkLobby.my_info.username = $Control/usernamefield.text if checkValidUser() else generateRandomName()
	$JOINdialogue.popup()
	pass # Replace with function body.

func checkValidUser() -> bool:
	var reg = RegEx.new()
	reg.compile("(?i)[^ ]([A-Za-z0-9])+")
	var result = reg.search($Control/usernamefield.text)
	if result:
		return true
	return false

func generateRandomName() -> String:
	randomize()
	var namelist0 = ["The","Barnicle","Blue","A ","Green","Super","Orange","Stupid","Likeness","Array","Fiendish","","OneMillion"]
	var namelist1 = ["Middle","Bastardized","Knight","Killer","Best","Worst","QWERTY","Stupid","Dumb","Console","Blaster","Monkey","Slayer"]
	var namelist2 = ["FromDownTown","Eagle","","Fuego","Shooter","Face","Kicker","TheSmall",str(randi()%1000),".com","live"]
	var newname = ""
	newname += namelist0[randi()%namelist0.size()]
	newname += namelist1[randi()%namelist1.size()]
	newname += namelist2[randi()%namelist2.size()]
	return newname
