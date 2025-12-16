extends Node

# --- CONFIGURATION DANS L'INSPECTEUR ---
# Au lieu d'écrire le code ici, on glissera nos fiches dans cette liste via l'Inspecteur
@export var base_de_donnees_deductions : Array[DonneeDeduction] = []
@export var bouton_inventaire : Button
# --- VARIABLES D'ETAT ---
var selection_actuelle : Array = []
var tous_les_indices : Array = []
var nombre_indices_survoles : int = 0
var input_bloque : bool = false

# On charge la scène du post-it
var post_it_scene = preload("res://post_it.tscn")

# Lien vers le conteneur qu'on vient de créer
@onready var conteneur_post_its = $"../ConteneurPostIts" 
# (Note: "../" suppose que le Manager est un enfant direct de la racine)

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
	var random_side = randi() % 4 # 0:Haut, 1:Bas, 2:Gauche, 3:Droite
	var pos = Vector2.ZERO
	
	# On ajoute un peu de hasard (variance) pour que ce ne soit pas trop aligné
	var variance = randf_range(-50, 50)
	
	match random_side:
		0: # HAUT
			pos.x = randf_range(-largeur_scene/2, largeur_scene/2)
			pos.y = -hauteur_scene/2 - marge_table + variance
		1: # BAS
			pos.x = randf_range(-largeur_scene/2, largeur_scene/2)
			pos.y = hauteur_scene/2 + marge_table + variance
		2: # GAUCHE
			pos.x = -largeur_scene/2 - marge_table + variance
			pos.y = randf_range(-hauteur_scene/2, hauteur_scene/2)
		3: # DROITE
			pos.x = largeur_scene/2 + marge_table + variance
			pos.y = randf_range(-hauteur_scene/2, hauteur_scene/2)
			
	return pos

func spawner_post_it(fiche : DonneeDeduction):
	# 1. Création
	var nouveau_post_it = post_it_scene.instantiate()
	
	# 2. Ajout à la scène (Table)
	conteneur_post_its.add_child(nouveau_post_it)
	
	# 3. Configuration
	nouveau_post_it.setup_postit(fiche.titre)
	
	# 4. Placement
	# Attention : Les contrôles UI (PanelContainer) sont ancrés par défaut en haut à gauche (0,0).
	# On doit centrer leur pivot pour que le placement soit joli.
	nouveau_post_it.position = trouver_position_libre_sur_table()
	
	# Petit effet de rotation pour le réalisme (c'est posé en vrac)
	nouveau_post_it.rotation_degrees = randf_range(-10, 10)

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
	if bouton_inventaire:
		bouton_inventaire.demarrer_clignotement()
	# Feedback Visuel "Or"
	for indice in tous_les_indices:
		if indice.id_indice in fiche_gagnante.indices_requis:
			if indice.highlight_visuel:
				indice.highlight_visuel.color = Color(0.0, 0.998, 0.065, 0.6)
	
	for fiche_existante in PartieGlobale.inventaire_deductions:
		spawner_post_it(fiche_existante)
	
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
