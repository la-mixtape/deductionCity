extends Button

var tween_clignotement : Tween

func _ready():
	# Au départ, le fond est blanc (couleur normale définie dans l'inspecteur)
	self_modulate = Color(1, 1, 1, 1)

func _on_pressed():
	arreter_clignotement()
	get_tree().change_scene_to_file("res://scene_inventaire.tscn")

func demarrer_clignotement():
	if tween_clignotement:
		tween_clignotement.kill()
	
	tween_clignotement = create_tween().set_loops()
	
	# Étape 1 : Le fond devient VERT FLUO en 0.5 seconde
	tween_clignotement.tween_property(self, "self_modulate", Color(0, 1, 0, 1), 0.5)
	
	# Étape 2 : Le fond redevient BLANC en 0.5 seconde
	tween_clignotement.tween_property(self, "self_modulate", Color(1, 1, 1, 1), 0.5)

func arreter_clignotement():
	if tween_clignotement:
		tween_clignotement.kill()
	# On remet le fond en blanc proprement
	self_modulate = Color(1, 1, 1, 1)
