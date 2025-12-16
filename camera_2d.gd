extends Camera2D

# --- Paramètres modifiables dans l'Inspecteur ---
# Vitesse du zoom
@export var zoom_speed : float = 0.1
# Zoom minimum (dézoom max)
@export var min_zoom : float = 0.35
# Zoom maximum (zoom max)
@export var max_zoom : float = 3.0
# Quel bouton de souris pour bouger la caméra ? (Ici : Clic Droit)
@export var drag_button : MouseButton = MOUSE_BUTTON_RIGHT

@export var zoom_vue_globale : Vector2 = Vector2(0.4, 0.4) # Plus le chiffre est petit, plus on voit loin

func _unhandled_input(event):
	# 1. Gestion du DEPLACEMENT (Panoramique)
	if event is InputEventMouseMotion:
		# Si le bouton droit (ou celui choisi) est maintenu enfoncé
		if event.button_mask == mouse_button_to_mask(drag_button):
			# On déplace la caméra dans le sens inverse de la souris
			# On divise par le zoom pour que la vitesse reste naturelle même zoomé
			position -= event.relative / zoom

	# 2. Gestion du ZOOM
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				apply_zoom(zoom_speed, event.position)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				apply_zoom(-zoom_speed, event.position)

func activer_vue_globale():
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "zoom", zoom_vue_globale, 0.8) # 0.8 secondes pour l'animation

# Fonction mathématique pour zoomer vers la souris
func apply_zoom(amount: float, mouse_anchor: Vector2):
	var old_zoom = zoom
	var new_zoom = old_zoom + Vector2(amount, amount)
	
	# On limite le zoom entre le min et le max
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	# Si on a atteint la limite, on arrête tout
	if new_zoom == old_zoom:
		return
	
	# --- La magie du zoom vers le curseur ---
	# 1. On calcule où est la souris dans le monde AVANT de zoomer
	var mouse_pos_world = get_global_mouse_position()
	
	# 2. On applique le nouveau zoom
	zoom = new_zoom
	
	# 3. On calcule où la souris se trouve MAINTENANT avec le nouveau zoom
	# (Note: get_global_mouse_position change quand le zoom change)
	var new_mouse_pos_world = get_global_mouse_position()
	
	# 4. On déplace la caméra de la différence pour que le point sous la souris reste stable
	position += (mouse_pos_world - new_mouse_pos_world)

# Petite fonction utilitaire pour convertir le bouton en masque
func mouse_button_to_mask(button: MouseButton) -> int:
	return 1 << (button - 1)


func _on_clue_shop_1_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.
