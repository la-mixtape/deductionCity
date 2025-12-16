extends Node

# --- CONFIGURATION DANS L'INSPECTEUR ---
# Au lieu d'écrire le code ici, on glissera nos fiches dans cette liste via l'Inspecteur
@export var base_de_donnees_deductions : Array[DonneeDeduction] = []
# --- VARIABLES D'ETAT ---
var selection_actuelle : Array = []
var tous_les_indices : Array = []
var nombre_indices_survoles : int = 0
var input_bloque : bool = false

@export var flash_visuel : ColorRect

@export var bouton_vue_globale : Button # Changez Control par Button si besoin

# On charge la scène du post-it
var post_it_scene = preload("res://post_it.tscn")

# Lien vers le conteneur qu'on vient de créer

@onready var conteneur_post_its = $"../ConteneurPostIts"
@onready var sprite_scene = $"../Sprite2D" # Référence à l'image centrale

# Configuration pour le placement
var taille_post_it = Vector2(160, 160) # 150 + une petite marge de 10px
var zones_occupees : Array[Rect2] = [] # On va stocker ici tout ce qui est déjà posé
# Dimensions de votre image centrale (à ajuster selon votre image !)
# Exemple pour une image 1920x1080
var largeur_scene = 1920
var hauteur_scene = 1080
var marge_table = 200 # Distance entre la photo et les post-its

func _ready():
	var scene_racine = get_parent()
	for enfant in scene_racine.get_children():
		if enfant is Indice:
			enfant.a_ete_clique.connect(_on_indice_clique)
			enfant.mouse_entered.connect(_on_souris_entre_indice)
			enfant.mouse_exited.connect(_on_souris_sort_indice)
			tous_les_indices.append(enfant)
	for fiche_existante in PartieGlobale.inventaire_deductions:
			spawner_post_it(fiche_existante)
			
func trouver_position_libre_sur_table() -> Vector2:
	# 1. On définit la zone interdite (l'image centrale)
	# On doit recalculer sa zone précise en tenant compte de son échelle
	var taille_image = sprite_scene.texture.get_size() * sprite_scene.scale
	var pos_image = sprite_scene.position - (taille_image / 2) # Coin haut-gauche
	var rect_image = Rect2(pos_image, taille_image)
	
	# Si c'est le premier appel, on initialise la liste avec l'image
	if zones_occupees.is_empty():
		zones_occupees.append(rect_image)

	# 2. Algorithme de recherche en spirale
	var centre_table = sprite_scene.position
	var angle = 0.0
	var rayon = (taille_image.x + taille_image.y) / 4 # On commence juste au bord de l'image
	var increment_rayon = 10.0 # On s'éloigne de 10px à chaque tour
	var increment_angle = 0.5 # Environ 30 degrés par pas
	
	# Sécurité pour ne pas boucler à l'infini (max 500 tentatives)
	for i in range(500):
		# Calcul de la position candidate (coordonnées polaires -> cartésiennes)
		var offset = Vector2(cos(angle), sin(angle)) * rayon
		var pos_candidate = centre_table + offset
		
		# On centre le post-it sur ce point (car pos_candidate est le centre souhaité)
		var pos_haut_gauche = pos_candidate - (taille_post_it / 2)
		
		# On crée le rectangle virtuel de ce futur post-it
		var rect_candidat = Rect2(pos_haut_gauche, taille_post_it)
		
		# 3. Vérification des collisions
		var collision = false
		for zone in zones_occupees:
			if rect_candidat.intersects(zone):
				collision = true
				break
		
		# 4. Si c'est libre, on valide !
		if not collision:
			zones_occupees.append(rect_candidat)
			return pos_haut_gauche # C'est cette position que le Node utilisera
			
		# Sinon, on continue de tourner et de s'éloigner
		angle += increment_angle
		rayon += increment_rayon * 0.1 # On augmente le rayon doucement
		
	return Vector2.ZERO # Fallback si vraiment pas de place (peu probable)

func spawner_post_it(fiche : DonneeDeduction) -> Node: 
	var nouveau_post_it = post_it_scene.instantiate()
	conteneur_post_its.add_child(nouveau_post_it)
	nouveau_post_it.setup_postit(fiche.titre)
	
	nouveau_post_it.position = trouver_position_libre_sur_table()
	nouveau_post_it.rotation_degrees = randf_range(-5, 5)
	
	return nouveau_post_it # <--- AJOUT IMPORTANT

func _on_souris_entre_indice():
	nombre_indices_survoles += 1

func _on_souris_sort_indice():
	nombre_indices_survoles -= 1

func _unhandled_input(event):
	if input_bloque: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if nombre_indices_survoles == 0:
				tout_reset()

func _on_indice_clique(indice_obj : Indice):
	if input_bloque: return

	var id = indice_obj.id_indice
	
	if indice_obj.est_selectionne:
		# Vérification prédictive avec la nouvelle structure de données
		var test_selection = selection_actuelle.duplicate()
		test_selection.append(id)
		
		if est_combinaison_potentielle(test_selection):
			selection_actuelle.append(id)
			verifier_hypotheses()
		else:
			print("Incohérence détectée avec l'objet : ", id)
			tout_reset()
	else:
		if id in selection_actuelle:
			selection_actuelle.erase(id)

func verifier_hypotheses():
	# On parcourt nos fiches de données configurées dans l'inspecteur
	for fiche in base_de_donnees_deductions:
		var hypothese = fiche.indices_requis.duplicate()
		
		selection_actuelle.sort()
		hypothese.sort()
		
		if selection_actuelle == hypothese:
			valider_deduction(fiche) # On passe la fiche entière pour avoir le titre !

func valider_deduction(fiche_gagnante : DonneeDeduction):
	print("DÉDUCTION VALIDÉE : ", fiche_gagnante.titre)
	PartieGlobale.ajouter_deduction(fiche_gagnante)
	
	input_bloque = true
	
	# 1. EFFET FLASH VERT
	if flash_visuel:
		var tween = create_tween()
		# On modifie "modulate:a" au lieu de "color:a"
		tween.tween_property(flash_visuel, "modulate:a", 0.5, 0.1)
		tween.tween_property(flash_visuel, "modulate:a", 0.0, 0.5)

	# Feedback Visuel indices (votre code existant)
	for indice in tous_les_indices:
		if indice.id_indice in fiche_gagnante.indices_requis:
			if indice.highlight_visuel:
				indice.highlight_visuel.color = Color(0.0, 0.998, 0.065, 0.6)
	
	# 2. SPAWN ET INDICATEUR
	# On récupère l'instance du nouveau post-it pour la donner à la flèche
	var nouveau_post_it = spawner_post_it(fiche_gagnante)

	if bouton_vue_globale:
		bouton_vue_globale.declencher_feedback_positif()

	await get_tree().create_timer(1.5).timeout
	
	tout_reset()
	input_bloque = false

func tout_reset():
	selection_actuelle.clear()
	for indice in tous_les_indices:
		indice.deselectionner()
	

# --- FONCTIONS UTILITAIRES ADAPTÉES ---

func est_combinaison_potentielle(liste_test: Array) -> bool:
	# On vérifie chaque fiche de la base de données
	for fiche in base_de_donnees_deductions:
		# On compare avec la liste d'IDs de la fiche
		if est_sous_ensemble(liste_test, fiche.indices_requis):
			return true
	return false

func est_sous_ensemble(petit_tab: Array, grand_tab: Array) -> bool:
	for element in petit_tab:
		if not element in grand_tab:
			return false
	return true
