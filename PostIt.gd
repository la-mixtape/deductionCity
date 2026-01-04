extends PanelContainer

@onready var label = $LabelTitre

# --- NOUVELLES VARIABLES DE STACKING ---
var est_objectif_vert : bool = false # Pour savoir si c'est une base de pile
var parent_post_it : Node = null     # Le post-it SUR lequel je suis posé
var enfant_post_it : Node = null     # Le post-it QUI est posé sur moi

var offset_stacking = Vector2(0, 50) # Le décalage visuel (50px plus bas)
# Configuration
var taille_max_police = 150
var taille_min_police = 40
var hauteur_max_disponible = 400 # 150px total - 20px de marges

var is_dragging : bool = false
var drag_offset : Vector2 = Vector2.ZERO

func definir_taille(nouvelle_taille : Vector2):
	custom_minimum_size = nouvelle_taille
	size = nouvelle_taille # On force la mise à jour immédiate
	
	# Si vous avez un Label à l'intérieur, assurez-vous qu'il est en mode "Autowrap"
	# pour que le texte s'adapte à la nouvelle largeur.

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

func attacher_a(nouvelle_cible : Node):
	# Si la cible a déjà un enfant, on essaie de s'attacher à l'enfant (récursif vers le bas)
	if nouvelle_cible.enfant_post_it != null:
		attacher_a(nouvelle_cible.enfant_post_it)
		return

	# Configuration des liens
	parent_post_it = nouvelle_cible
	nouvelle_cible.enfant_post_it = self
	
	# Placement visuel
	position_visuelle_sur_parent()
	
	# Gestion de l'ordre d'affichage (Z-index)
	# On doit passer devant le parent
	move_to_front() 

func detacher():
	if parent_post_it != null:
		parent_post_it.enfant_post_it = null
		parent_post_it = null

func position_visuelle_sur_parent():
	if parent_post_it:
		# --- MODIFICATION ---
		# Au lieu d'un offset fixe, on calcule la position relative à la taille du parent.
		
		# On récupère la hauteur du parent
		var hauteur_parent = parent_post_it.size.y
		
		# On définit de combien de pixels on veut laisser dépasser le parent (la zone de texte visible)
		# Ici, on laisse 70% du parent visible, l'enfant s'accroche dans les 30% du bas.
		# Vous pouvez ajuster le ratio (0.7) ou mettre une valeur fixe (ex: hauteur_parent - 60)
		var offset_y = hauteur_parent * 0.7 
		
		var offset_dynamique = Vector2(0, offset_y)
		
		# Application de la position
		global_position = parent_post_it.global_position + offset_dynamique
		# --------------------

func deplacer_pile(delta_mouvement : Vector2):
	# Cette fonction est appelée par le parent quand il bouge
	global_position += delta_mouvement
	
	# Si j'ai moi-même un enfant, je lui transmets le mouvement
	if enfant_post_it:
		enfant_post_it.deplacer_pile(delta_mouvement)

func ramener_pile_au_premier_plan():
	# Fonction récursive pour que toute la pile passe devant
	move_to_front()
	if enfant_post_it:
		enfant_post_it.ramener_pile_au_premier_plan()

func trouver_cible_sous_souris() -> Node:
	# Si je suis une base (Vert), je ne peux m'attacher à rien.
	# Cela m'empêche de me stacker sur un autre Vert, 
	# et aussi de m'attacher par erreur à mes propres enfants (Jaunes).
	if est_objectif_vert:
		return null
	# On cherche un Post-It valide sous la souris
	var tous_les_post_its = get_parent().get_children()
	var ma_zone = get_global_rect()
	
	for autre in tous_les_post_its:
		if autre == self: continue # On ne se teste pas soi-même
		if not (autre is PanelContainer): continue # Sécurité
		if "est_objectif_vert" not in autre: continue # Sécurité type
		if autre == enfant_post_it:
			continue
		
		# RÈGLE : On ne peut s'attacher qu'à un Vert ou un Jaune qui est DÉJÀ dans une pile verte
		# Si l'autre est jaune et n'a pas de parent, on ne peut pas commencer une pile dessus
		if not autre.est_objectif_vert and autre.parent_post_it == null:
			continue
			
		# Détection de collision simple
		if autre.get_global_rect().intersects(ma_zone):
			return autre
			
	return null
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# --- DÉBUT DU DRAG ---
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				
				# 1. Si on est attaché, on se détache (on prend la carte en main)
				if parent_post_it:
					detacher()
				
				# 2. Visuel : On met ce post-it et ses enfants au premier plan
				ramener_pile_au_premier_plan()
				
				accept_event()
				
			else:
				# --- FIN DU DRAG (RELÂCHEMENT) ---
				is_dragging = false
				
				# 1. On cherche si on a lâché sur une pile valide
				var cible = trouver_cible_sous_souris()
				if cible:
					attacher_a(cible)
				
				accept_event()

	elif event is InputEventMouseMotion:
		if is_dragging:
			# --- MOUVEMENT ---
			var ancienne_pos = global_position
			var nouvelle_pos = get_global_mouse_position() + drag_offset
			
			# Calcul du delta pour bouger les enfants
			var delta = nouvelle_pos - ancienne_pos
			
			global_position = nouvelle_pos
			
			# Si j'ai des enfants accrochés à moi, je les tire aussi
			if enfant_post_it:
				enfant_post_it.deplacer_pile(delta)
				
			accept_event()
			
func changer_couleur(nouvelle_couleur : Color):
	# On récupère le style actuel (le fond jaune)
	var style_actuel = get_theme_stylebox("panel")
	
	if style_actuel:
		# IMPORTANT : On le duplique pour que le changement soit unique à CE post-it
		# Sinon, tous les post-its du jeu changeraient de couleur !
		var nouveau_style = style_actuel.duplicate()
		
		# On vérifie si c'est bien une couleur unie (StyleBoxFlat)
		if nouveau_style is StyleBoxFlat:
			nouveau_style.bg_color = nouvelle_couleur
			
			# On applique ce nouveau style vert uniquement à ce nœud
			add_theme_stylebox_override("panel", nouveau_style)
		else:
			# Fallback : Si vous utilisez une image (Texture), on la teinte
			self_modulate = nouvelle_couleur

func jouer_effet_focus():
	# On s'assure d'être au premier plan pour être vu
	ramener_pile_au_premier_plan()
	
	var tween = create_tween()
	# Petit effet de "pop" (agrandissement) + Flash couleur
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.1) # Plus lumineux
	
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# On le fait 2 fois
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
