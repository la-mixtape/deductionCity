extends Area2D
class_name Indice

@export var id_indice : String = ""

# Couleur du survol (Blanc semi-transparent)
var couleur_survol = Color(0.0, 0.596, 0.596, 0.427)
# Couleur de sélection (Vert semi-transparent)
var couleur_selection = Color(0.898, 0.85, 0.0, 0.5)

var est_selectionne : bool = false
var highlight_visuel : Polygon2D = null # Notre forme colorée générée

signal a_ete_clique(indice_concerne)

func _ready():
	# 1. On cherche le CollisionPolygon2D existant
	var collision_shape = get_node_or_null("CollisionPolygon2D")
	
	if collision_shape:
		# 2. On crée dynamiquement un Polygon2D (le jumeau visuel)
		highlight_visuel = Polygon2D.new()
		
		# 3. On lui donne exactement la même forme que la zone de clic
		highlight_visuel.polygon = collision_shape.polygon
		highlight_visuel.position = collision_shape.position
		
		# 4. On le rend invisible par défaut
		highlight_visuel.visible = false
		
		# 5. On l'ajoute à l'objet
		add_child(highlight_visuel)
	else:
		print("ERREUR : L'indice " + name + " n'a pas de CollisionPolygon2D !")

# --- GESTION DES CLICS ---
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			est_selectionne = !est_selectionne
			actualiser_visuel()
			emit_signal("a_ete_clique", self)

# --- GESTION DU SURVOL (Sign & Feedback) ---
# Note : Vous n'avez rien à connecter manuellement si vous utilisez 
# les signaux intégrés mouse_entered/exited via l'interface, 
# MAIS ici on va utiliser les fonctions virtuelles natives de Godot pour simplifier :

func _mouse_enter():
	# Quand la souris rentre, on montre le highlight (si pas déjà sélectionné)
	if highlight_visuel and not est_selectionne:
		highlight_visuel.color = couleur_survol
		highlight_visuel.visible = true

func _mouse_exit():
	# Quand la souris sort, on cache le highlight (si pas déjà sélectionné)
	if highlight_visuel and not est_selectionne:
		highlight_visuel.visible = false

# --- MISE A JOUR VISUELLE ---
func actualiser_visuel():
	if highlight_visuel:
		if est_selectionne:
			highlight_visuel.color = couleur_selection
			highlight_visuel.visible = true
		else:
			# Si on désélectionne, on regarde si la souris est encore dessus
			# pour savoir si on laisse le highlight de survol ou si on éteint tout.
			# (C'est un petit détail de finition pro)
			highlight_visuel.visible = false
			# Petite astuce : on relance la logique de survol au cas où la souris est encore là
			# (Optionnel, mais plus propre)
			#_mouse_enter() 

func deselectionner():
	est_selectionne = false
	actualiser_visuel()
