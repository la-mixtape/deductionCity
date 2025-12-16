extends Button

@export var camera_scene : Camera2D
@export var cible_a_centrer : Node2D # <-- NOUVEAU : L'objet à viser (votre Sprite2D)

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if not camera_scene:
		print("ERREUR : Caméra non reliée dans l'inspecteur")
		return

	# On récupère la position de la cible (ou (0,0) si oubliée)
	var position_cible = Vector2.ZERO
	if cible_a_centrer:
		position_cible = cible_a_centrer.global_position
	else:
		print("ATTENTION : Cible à centrer non reliée, on vise (0,0)")

	# On appelle la fonction en lui donnant la destination
	if camera_scene.has_method("activer_vue_globale"):
		camera_scene.activer_vue_globale(position_cible)

func declencher_feedback_positif():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
