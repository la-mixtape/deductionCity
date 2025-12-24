extends Node

# --- CONFIGURATION DANS L'INSPECTEUR ---
# Au lieu d'écrire le code ici, on glissera nos fiches dans cette liste via l'Inspecteur
@export var base_de_donnees_deductions : Array[DonneeDeduction] = []

@export_multiline var objectifs_initiaux : Array[String] = [
	"Qui a tué la victime ?",
    "Quelle est l'arme du crime ?"
]

# --- VARIABLES D'ETAT ---
var selection_actuelle : Array = []
var tous_les_indices : Array = []
var nombre_indices_survoles : int = 0
var input_bloque : bool = false




@export var bouton_vue_globale : Button # Changez Control par Button si besoin

# On charge la scène du post-it
var post_it_scene = preload("res://post_it.tscn")

# Lien vers le conteneur qu'on vient de créer

@onready var conteneur_post_its = $"../ConteneurPostIts"
@onready var sprite_scene = $"../Sprite2D" # Référence à l'image centrale

# Configuration pour le placement
@export_group("Configuration Post-Its")
@export var taille_post_it_jaune : Vector2 = Vector2(160, 160)
@export var taille_post_it_vert : Vector2 = Vector2(250, 100) # Souvent plus large pour les questions

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
			
	call_deferred("spawner_post_its_objectifs")

# Version simplifiée pour créer un post-it juste avec du texte
# On ajoute un deuxième argument optionnel "pos_forcee"
func spawner_post_it_virtuel(texte : String, taille_a_utiliser : Vector2, pos_forcee = null) -> Node:
	var nouveau_post_it = post_it_scene.instantiate()
	conteneur_post_its.add_child(nouveau_post_it)
	nouveau_post_it.setup_postit(texte)
	
	# 1. On applique la taille visuelle
	nouveau_post_it.definir_taille(taille_a_utiliser)
	
	if pos_forcee != null:
		# Cas A : Position imposée (Objectifs Verts)
		nouveau_post_it.position = pos_forcee
		
		# On enregistre la zone occupée avec la bonne taille
		var rect = Rect2(pos_forcee, taille_a_utiliser)
		zones_occupees.append(rect)
	else:
		# Cas B : Placement auto (Post-its Jaunes)
		# On demande à l'algo de chercher une place pour CETTE taille
		nouveau_post_it.position = trouver_position_libre_sur_table(taille_a_utiliser)
	
	nouveau_post_it.rotation_degrees = randf_range(-3, 3)
	return nouveau_post_it

func spawner_post_its_objectifs():
	var vert_objectif = Color(0.6, 0.9, 0.6)
	
	# 1. Calculs de géométrie pour trouver le bord gauche
	var taille_image = sprite_scene.texture.get_size() * sprite_scene.scale
	# On part du centre (position) et on retire la moitié de la largeur
	var bord_gauche_image = sprite_scene.position.x - (taille_image.x / 2)
	
	# On se décale encore de 200 pixels vers la gauche pour ne pas toucher l'image
	var x_cible = bord_gauche_image - 250.0 
	
	# On commence un peu plus haut que le centre vertical
	var y_depart = sprite_scene.position.y - 150.0
	
	# 2. Création des post-its
	for i in range(objectifs_initiaux.size()):
		var question = objectifs_initiaux[i]
		
		# On calcule une position en colonne (l'un sous l'autre)
		# On ajoute 180px verticalement entre chaque post-it
		var pos_calculee = Vector2(x_cible, y_depart + (i * 180.0))
		
		# On ajoute un petit décalage aléatoire pour faire "naturel"
		var decalage_random = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		
		# Appel avec la position forcée
		var post_it = spawner_post_it_virtuel(question, taille_post_it_vert, pos_calculee + decalage_random)
		post_it.changer_couleur(vert_objectif)
		
func trouver_position_libre_sur_table(taille_objet : Vector2) -> Vector2:
	# 1. On définit la zone interdite (l'image centrale)
	# On doit recalculer sa zone précise en tenant compte de son échelle
	var taille_image = sprite_scene.texture.get_size() * sprite_scene.scale
	var pos_image = sprite_scene.position - (taille_image / 2) # Coin haut-gauche
	var rect_image = Rect2(pos_image, taille_image)
	
	# Si c'est le premier appel, on initialise la liste avec l'image
	if zones_occupees.is_empty():
		zones_occupees.append(rect_image)

# Algorithme spirale (inchangé sauf l'utilisation de taille_objet)
	var centre_table = sprite_scene.position
	var angle = 0.0
	var rayon = (taille_image.x + taille_image.y) / 4
	var increment_rayon = 10.0
	var increment_angle = 0.5
	
	for i in range(500):
		var offset = Vector2(cos(angle), sin(angle)) * rayon
		var pos_candidate = centre_table + offset
		
		# ICI : On utilise la taille spécifique passée en argument
		var pos_haut_gauche = pos_candidate - (taille_objet / 2)
		var rect_candidat = Rect2(pos_haut_gauche, taille_objet)
		
		var collision = false
		for zone in zones_occupees:
			if rect_candidat.intersects(zone):
				collision = true
				break
		
		if not collision:
			zones_occupees.append(rect_candidat)
			return pos_haut_gauche
			
		angle += increment_angle
		rayon += increment_rayon * 0.1
		
	return Vector2.ZERO
func spawner_post_it(fiche : DonneeDeduction) -> Node:
	# On appelle le virtuel en passant la taille JAUNE et "null" pour la position forcée
	var nouveau_post_it = spawner_post_it_virtuel(fiche.titre, taille_post_it_jaune, null)
	return nouveau_post_it

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
	
	# Feedback Visuel indices (votre code existant)
	for indice in tous_les_indices:
			if indice.id_indice in fiche_gagnante.indices_requis:
				# Au lieu de juste changer la couleur, on lance l'animation
				indice.jouer_animation_validation()
	
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
