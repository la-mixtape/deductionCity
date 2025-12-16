extends Button

# MODIFICATION : On utilise @export pour relier la caméra manuellement
@export var camera_scene : Camera2D

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	# Petite sécurité : si la caméra n'est pas reliée, on affiche une erreur
	if not camera_scene:
		print("ERREUR : La caméra n'est pas reliée au bouton dans l'inspecteur !")
		return

	# On lance le dézoom
	if camera_scene.has_method("activer_vue_globale"):
		camera_scene.activer_vue_globale()
	else:
		print("ERREUR : Le script camera_2d.gd n'a pas la fonction 'activer_vue_globale'")

func declencher_feedback_positif():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
