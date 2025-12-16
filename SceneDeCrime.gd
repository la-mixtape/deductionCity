extends Node2D

func _unhandled_input(event):
	# Cette fonction ne se déclenche que si PERSONNE D'AUTRE n'a traité le clic avant.
	# Comme nos Indices font "set_input_as_handled()", ils bloquent cette fonction.
	# Donc si on arrive ici, c'est qu'on a cliqué dans le vide !
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# On appelle la fonction reset du Manager
			# Assurez-vous que votre noeud Manager s'appelle bien "EnqueteManager"
			$EnqueteManager.tentative_reset_depuis_fond()
