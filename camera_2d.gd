extends Camera2D

# --- Paramètres modifiables ---
@export var zoom_speed : float = 0.1
@export var min_zoom : float = 0.3
@export var max_zoom : float = 4.5
@export var drag_button : MouseButton = MOUSE_BUTTON_RIGHT

# La vue "Bureau Détective"
@export var zoom_vue_globale : Vector2 = Vector2(0.4, 0.4) 

# Le palier de blocage (Vue Image Entière)
@export var zoom_palier_image : float = 1.0 
# L'image à centrer
@export var cible_image : Node2D 

# Variable pour gérer le Tween d'animation
var tween_snap : Tween

func _unhandled_input(event):
	# 1. Gestion du DEPLACEMENT
	if event is InputEventMouseMotion:
		if event.button_mask == mouse_button_to_mask(drag_button):
			position -= event.relative / zoom
			# Si le joueur bouge la main, on tue l'animation de centrage
			if tween_snap and tween_snap.is_running():
				tween_snap.kill()

	# 2. Gestion du ZOOM
	# 1. Gestion Souris Classique (Ton code actuel)
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				apply_zoom(zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				apply_zoom(-zoom_speed)
	
	# 2. Gestion du "Pincement" (Pinch to zoom)
	# C'est la façon la plus naturelle de zoomer au trackpad
	elif event is InputEventMagnifyGesture:
		# event.factor est > 1 pour un zoom avant, < 1 pour un zoom arrière
		# On ajuste le facteur pour qu'il corresponde à ta logique de zoom
		var zoom_amount = (event.factor - 1.0) * zoom_speed
		apply_zoom(zoom_amount)

	# 3. Gestion du Défilement Trackpad (Pan Gesture)
	# Si l'utilisateur scrolle à 2 doigts au lieu de pincer
	elif event is InputEventPanGesture:
		# delta.y contient le mouvement vertical des doigts
		# On multiplie par une petite valeur car le Pan est très sensible
		var pan_zoom = event.delta.y * 0.1 
		# Attention : sur trackpad Mac, le sens peut être inversé selon les réglages "Naturel"
		apply_zoom(-pan_zoom * zoom_speed)

func apply_zoom(amount: float):
	var old_zoom_val = zoom.x
	var new_zoom_val = old_zoom_val + amount
	
	# --- DEBUG ---
	print("Zoom Actuel : %.2f | Cible : %.2f" % [old_zoom_val, new_zoom_val])

	# --- 1. SÉCURITÉ ANTI-PIÈGE ---
	# Si on est déjà très proche du palier (à +/- 0.05), on NE snap PAS.
	# Cela permet au joueur de s'échapper du palier.
	if abs(old_zoom_val - zoom_palier_image) < 0.05:
		print(">> Déjà sur le palier, mouvement autorisé pour sortir.")
		executer_zoom_normal(new_zoom_val)
		return

	# --- 2. LOGIQUE DE SNAP ---
	var on_traverse_le_palier = false
	
	# On traverse vers le bas (Détails -> Bureau)
	if old_zoom_val > zoom_palier_image and new_zoom_val <= zoom_palier_image:
		on_traverse_le_palier = true
		
	# On traverse vers le haut (Bureau -> Détails)
	elif old_zoom_val < zoom_palier_image and new_zoom_val >= zoom_palier_image:
		on_traverse_le_palier = true
	
	if on_traverse_le_palier:
		snap_camera_sur_image()
		return 

	# --- 3. ZOOM NORMAL ---
	executer_zoom_normal(new_zoom_val)

func executer_zoom_normal(target_zoom_val : float):
	var new_zoom = Vector2(target_zoom_val, target_zoom_val)
	
	# Limites
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	if new_zoom == zoom:
		return
	
	# Zoom vers la souris
	var mouse_pos_world = get_global_mouse_position()
	zoom = new_zoom
	var new_mouse_pos_world = get_global_mouse_position()
	position += (mouse_pos_world - new_mouse_pos_world)

func snap_camera_sur_image():
	print(">>> SNAP ACTIVÉ ! Centrage sur l'image.")
	
	# On tue l'ancien tween s'il existe
	if tween_snap: tween_snap.kill()
	tween_snap = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_snap.set_parallel(true)
	
	# 1. On force le zoom exact du palier
	tween_snap.tween_property(self, "zoom", Vector2(zoom_palier_image, zoom_palier_image), 0.25)
	
	# 2. Si on a une image cible, on se centre dessus
	if cible_image:
		tween_snap.tween_property(self, "position", cible_image.global_position, 0.25)

func focus_sur_position(cible_pos: Vector2):
	# On tue le tween en cours s'il y en a un
	if tween_snap: tween_snap.kill()
	
	tween_snap = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_snap.set_parallel(true)
	
	# 1. Déplacement vers la cible
	tween_snap.tween_property(self, "position", cible_pos, 0.8)
	
	# 2. Zoom confortable (par exemple 1.0 pour lire le post-it)
	# Vous pouvez ajuster ce 1.0 selon la taille de vos textes
	tween_snap.tween_property(self, "zoom", Vector2(0.5, 0.5), 0.8)

func activer_vue_globale(target_position : Vector2 = Vector2.ZERO):
	if tween_snap: tween_snap.kill()
	tween_snap = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_snap.set_parallel(true)
	tween_snap.tween_property(self, "zoom", zoom_vue_globale, 0.8)
	tween_snap.tween_property(self, "position", target_position, 0.8)

func mouse_button_to_mask(button: MouseButton) -> int:
	return 1 << (button - 1)
