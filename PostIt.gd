extends PanelContainer

@onready var label = $LabelTitre

# Configuration
var taille_max_police = 24
var taille_min_police = 8
var hauteur_max_disponible = 130 # 150px total - 20px de marges

var is_dragging : bool = false
var drag_offset : Vector2 = Vector2.ZERO

func setup_postit(texte_a_afficher : String):
	label.text = texte_a_afficher
	
	# 1. On commence par la taille maximale
	var taille_actuelle = taille_max_police
	changer_taille_police(taille_actuelle)
	
	# 2. La boucle magique
	# On réduit la taille tant que ça dépasse
	while est_trop_grand() and taille_actuelle > taille_min_police:
		taille_actuelle -= 1
		changer_taille_police(taille_actuelle)

func changer_taille_police(taille : int):
	# On applique la nouvelle taille
	label.add_theme_font_size_override("font_size", taille)

func est_trop_grand() -> bool:
	# C'est ici la correction pour Godot 4 :
	# On demande au Label : "Combien as-tu de lignes ?" et "Quelle est la hauteur d'une ligne ?"
	var hauteur_reelle = label.get_line_count() * label.get_line_height()
	
	return hauteur_reelle > hauteur_max_disponible

func _gui_input(event):
	# 1. Clic gauche enfoncé ou relâché
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Début du drag
				is_dragging = true
				
				# On calcule l'écart entre le coin haut-gauche du post-it et la souris
				drag_offset = global_position - get_global_mouse_position()
				
				# Visuel : On met ce post-it au premier plan (devant les autres)
				move_to_front()
				
				# Important : On dit au moteur "J'ai géré cet événement, ne le passe pas à la caméra"
				accept_event()
				
			else:
				# Fin du drag
				is_dragging = false
				accept_event()

	# 2. Mouvement de la souris
	elif event is InputEventMouseMotion:
		if is_dragging:
			# On applique la nouvelle position en respectant l'écart d'origine
			global_position = get_global_mouse_position() + drag_offset
			accept_event()
