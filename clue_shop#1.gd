extends Area2D

# Cette fonction est appelée par Godot quand la souris fait quelque chose DANS la zone
func _on_input_event(viewport, event, shape_idx):
	# On vérifie si c'est un bouton de souris qui est pressé
	if event is InputEventMouseButton:
		# On vérifie si c'est le clic GAUCHE et si on vient d'appuyer (et pas relâcher)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Vous avez cliqué sur le Couteau !")
			# Ici, plus tard, on ajoutera le code pour ouvrir une fenêtre de dialogue
