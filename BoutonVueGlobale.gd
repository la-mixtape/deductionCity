extends Button

# Référence à la caméra (on la cherchera automatiquement au démarrage)
var camera_scene : Camera2D

func _ready():
	# On cherche le noeud Camera2D dans la scène principale
	# (Adaptez le chemin si votre caméra est rangée ailleurs)
	camera_scene = get_tree().get_first_node_in_group("Camera") 
	# ASTUCE : Ajoutez votre noeud Camera2D au groupe "Camera" dans l'inspecteur (Onglet Node > Groups)
	# SINON, utilisez un chemin direct : camera_scene = $"../../Camera2D"

	# On connecte le clic
	pressed.connect(_on_pressed)

func _on_pressed():
	# On arrête le clignotement s'il y en a un
	modulate = Color.WHITE
	
	# On lance le dézoom
	if camera_scene:
		if camera_scene.has_method("activer_vue_globale"):
			camera_scene.activer_vue_globale()

func declencher_feedback_positif():
	# Une petite animation pour dire "Coucou, clique ici !"
	var tween = create_tween()
	# Flash Vert
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Petit effet de scale (optionnel, attention au pivot)
	# tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	# tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
