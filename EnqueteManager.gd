extends Node

# --- CONFIGURATION DANS L'INSPECTEUR ---
# Au lieu d'écrire le code ici, on glissera nos fiches dans cette liste via l'Inspecteur
@export var base_de_donnees_deductions : Array[DonneeDeduction] = []

@export_group("Configuration Scénario")

# 1. Ceux qui apparaissent tout de suite (Liste simple)
@export_multiline var objectifs_demarrage : Array[String] = [
	"Qui a tué la victime ?",
	"Quelle est l'arme du crime ?"
]

# 2. Ceux qui apparaissent au clic (Dictionnaire ID -> Question)
@export_group("Configuration Objectifs Cachés")
# Liste 1 : Les IDs des indices (ex: "clueShopkeeper")
@export var ids_indices_caches : Array[String] = []
# Liste 2 : Les questions correspondantes (ex: "Quel est le lien ?")
@export_multiline var questions_caches : Array[String] = []

@export var camera_scene : Camera2D # <--- GLISSEZ VOTRE CAMERA ICI DANS L'INSPECTEUR
var post_its_actifs_par_titre : Dictionary = {}

@export var texture_point_interrogation : Texture2D # Glissez votre image "?" ici dans l'inspecteur
@export var texture_echec : Texture2D
var case_mystere_active : Node = null # Pour garder une trace de la case "?"

# On garde le dictionnaire pour la logique interne, mais on ne l'exporte plus
var objectifs_caches : Dictionary = {}


# --- VARIABLES D'ETAT ---
var selection_actuelle : Array = []
var tous_les_indices : Array = []
var nombre_indices_survoles : int = 0
var input_bloque : bool = false
var nombre_objectifs_verts_affiches : int = 0


@export var bouton_vue_globale : Button # Changez Control par Button si besoin

# On charge la scène du post-it
var post_it_scene = preload("res://post_it.tscn")

# Lien vers le conteneur qu'on vient de créer

@onready var conteneur_post_its = $"../ConteneurPostIts"
@onready var sprite_scene = $"../Sprite2D" # Référence à l'image centrale
@onready var conteneur_cases = $"../FeedbackUI/ColonneBD/VBoxContainer" # Vérifie le chemin exact !
var scene_case_bd = preload("res://CaseBD.tscn")
# Dictionnaire pour garder une trace des cases créées {id_indice : noeud_case}
var cases_actives = {}
# Configuration pour le placement
@export_group("Configuration Post-Its")
@export var taille_post_it_jaune : Vector2 = Vector2(160, 160)
@export var taille_post_it_vert : Vector2 = Vector2(250, 100) # Souvent plus large pour les questions

var zones_occupees : Array[Rect2] = [] # On va stocker ici tout ce qui est déjà posé
# Dimensions de votre image centrale (à ajuster selon votre image !)
# Exemple pour une image 1920x1080
var largeur_scene = 7322
var hauteur_scene = 4784
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
			generer_recompenses_deduction(fiche_existante)
	# On fusionne les deux tableaux de l'inspecteur
	for i in range(min(ids_indices_caches.size(), questions_caches.size())):
		var id = ids_indices_caches[i]
		var question = questions_caches[i]
		
		# Sécurité pour éviter les champs vides
		if id != "" and question != "":
			objectifs_caches[id] = question		
	call_deferred("lancer_objectifs_debut")

func lancer_objectifs_debut():
	for question in objectifs_demarrage:
		spawner_un_objectif_vert(question)

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

func spawner_un_objectif_vert(texte_question : String):
	var vert_objectif = Color(0.6, 0.9, 0.6)
	
	# --- CALCUL DE LA POSITION ---
	# On veut qu'ils apparaissent de droite à gauche (partant de l'image)
	# ou de gauche à droite selon ta préférence.
	# Ici : Le 1er se colle à l'image, le 2ème se met à sa gauche, etc.
	
	var taille_image = sprite_scene.texture.get_size() * sprite_scene.scale
	var bord_gauche_image = sprite_scene.position.x - (taille_image.x / 2)
	
	var largeur_post_it = taille_post_it_vert.x
	var marge_entre_post_its = 20.0
	var marge_par_rapport_image = 200
	
	# Calcul de la position X (On recule vers la gauche à chaque nouveau post-it)
	# (nombre_objectifs_verts_affiches + 1) car c'est le "n-ième" post-it
	var decalage_total = (nombre_objectifs_verts_affiches + 1) * (largeur_post_it + marge_entre_post_its)
	var x_cible = bord_gauche_image - decalage_total - marge_par_rapport_image 
	# Note: Le "+ largeur_post_it" sert à ajuster le pivot si tes post-its sont centrés ou non.
	# Ajuste simplement "x_cible" si tu trouves qu'ils sont trop loin/trop près.
	
	var y_fixe = sprite_scene.position.y - 900
	var pos_calculee = Vector2(x_cible, y_fixe)
	
	# Petit randomness
	var decalage_random = Vector2(randf_range(-5, 5), randf_range(-5, 5))
	
	# --- SPAWN ---
	var post_it = spawner_post_it_virtuel(texte_question, taille_post_it_vert, pos_calculee + decalage_random)
	post_it.changer_couleur(vert_objectif)
	post_it.est_objectif_vert = true  # C'est une BASE valide pour une pile	
	# On incrémente le compteur pour que le prochain se mette à côté
	nombre_objectifs_verts_affiches += 1
	return post_it
		
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
	
func generer_recompenses_deduction(fiche : DonneeDeduction) -> Array:
	var nouveaux_nodes : Array = []
	
	# 1. On vérifie s'il y a des récompenses définies, sinon on utilise le titre (rétro-compatibilité)
	var textes_jaunes = fiche.conclusions_jaunes.duplicate()
	var textes_verts = fiche.questions_vertes.duplicate()
	
	if textes_jaunes.is_empty() and textes_verts.is_empty():
		textes_jaunes.append(fiche.titre) # Fallback : on crée un jaune avec le titre
	
	# 2. Génération des Jaunes (Conclusions)
	for texte in textes_jaunes:
		# Position auto (null) et taille jaune
		var p = spawner_post_it_virtuel(texte, taille_post_it_jaune, null)
		p.est_objectif_vert = false
		nouveaux_nodes.append(p)
		
	# 3. Génération des Verts (Nouvelles Questions)
	for texte in textes_verts:
		# Utilise ta logique de placement à gauche
		var p = spawner_un_objectif_vert(texte)
		nouveaux_nodes.append(p)
	
	# 4. On enregistre tout ça sous le titre de la fiche
	post_its_actifs_par_titre[fiche.titre] = nouveaux_nodes
	
	return nouveaux_nodes

func ajouter_case_bd(id_indice: String, texture: Texture2D, texte: String):
	# Si la case existe déjà ou si pas d'image définie, on ignore
	if id_indice in cases_actives: return
	
	var nouvelle_case = scene_case_bd.instantiate()
	conteneur_cases.add_child(nouvelle_case)
	
	# On configure la case
	nouvelle_case.setup_case(texture, texte)
	
	# On stocke la référence pour pouvoir la supprimer plus tard
	cases_actives[id_indice] = nouvelle_case
	
	# Petit scroll automatique vers le bas pour voir la nouvelle case
	await get_tree().process_frame
	var scroll_container = conteneur_cases.get_parent()
	if scroll_container is ScrollContainer:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func retirer_case_bd(id_indice: String):
	if id_indice in cases_actives:
		var case_a_supprimer = cases_actives[id_indice]
		cases_actives.erase(id_indice)
		
		# Animation de sortie (optionnel) ou suppression directe
		case_a_supprimer.queue_free()

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
	
	# (Gestion objectifs cachés existante...)
	if id in objectifs_caches:
		var texte_question = objectifs_caches[id]
		spawner_un_objectif_vert(texte_question)
		objectifs_caches.erase(id) 
	
	if indice_obj.est_selectionne:
		# --- CAS : AJOUT D'UN INDICE ---
		var test_selection = selection_actuelle.duplicate()
		test_selection.append(id)
		
		if est_combinaison_potentielle(test_selection):
			selection_actuelle.append(id)
			
			# 1. D'abord on affiche la VRAIE case de l'indice cliqué
			ajouter_case_bd(id, indice_obj.image_bd, indice_obj.texte_bd)
			
			# 2. Ensuite, on recalcule le "?" (qui se mettra EN DESSOUS)
			mettre_a_jour_case_mystere()
			
			verifier_hypotheses()
		else:
			print("Incohérence détectée avec l'objet : ", id)
			# 1. On bloque tout pour que le joueur voie son erreur
			input_bloque = true
			
			# 2. Si une case "?" est affichée, on la transforme en alerte
			if is_instance_valid(case_mystere_active):
				var tex_fail = texture_echec
				# Sécurité si vous oubliez de mettre l'image
				if tex_fail == null: tex_fail = preload("res://icon.svg") 
				
				# On réutilise setup_case : cela change l'image ET rejoue le petit "pop"
				# Le clignotement continuera (en rouge), ce qui renforce l'effet d'alarme
				case_mystere_active.setup_case(tex_fail, "Mmmh...")
				
				# Optionnel : Forcer la couleur en rouge si votre image est blanche
				# case_mystere_active.modulate = Color.RED 
			
			# 3. On laisse le joueur contempler son erreur pendant 1 seconde
			await get_tree().create_timer(1.0).timeout
			
			# 4. On nettoie tout et on rend la main
			tout_reset()
			input_bloque = false
	else:
		# --- CAS : RETRAIT D'UN INDICE ---
		if id in selection_actuelle:
			selection_actuelle.erase(id)
			
			# 1. On retire la vraie case
			retirer_case_bd(id)
			
			# 2. On met à jour le "?" (il peut réapparaître ou disparaître)
			mettre_a_jour_case_mystere()

func verifier_hypotheses():
	# On parcourt nos fiches de données configurées dans l'inspecteur
	for fiche in base_de_donnees_deductions:
		var hypothese = fiche.indices_requis.duplicate()
		
		selection_actuelle.sort()
		hypothese.sort()
		
		if selection_actuelle == hypothese:
			valider_deduction(fiche) # On passe la fiche entière pour avoir le titre !

func mettre_a_jour_case_mystere():
	# 1. On nettoie toujours l'ancienne case mystère pour éviter les doublons ou problèmes d'ordre
	if is_instance_valid(case_mystere_active):
		case_mystere_active.queue_free()
		case_mystere_active = null
	
	# Si rien n'est sélectionné, on ne montre rien
	if selection_actuelle.is_empty():
		return

	# 2. On cherche quelle déduction le joueur vise
	var fiche_cible = trouver_deduction_cible(selection_actuelle)
	
	# Si la combinaison est invalide (ne mène à rien), on ne montre pas de suite
	if fiche_cible == null:
		return
		
	# 3. On compare : A-t-on tout trouvé ?
	var nombre_requis = fiche_cible.indices_requis.size()
	var nombre_actuel = selection_actuelle.size()
	
	if nombre_actuel < nombre_requis:
		# Il manque des éléments -> On affiche le "?"
		ajouter_case_mystere_visuelle()

func ajouter_case_mystere_visuelle():
	# Création de la case (comme une vraie case BD)
	var nouvelle_case = scene_case_bd.instantiate()
	conteneur_cases.add_child(nouvelle_case)
	
	# On la configure avec le "?" et un texte explicatif (ou vide)
	# Note : Assurez-vous d'avoir assigné une texture dans l'inspecteur !
	var tex = texture_point_interrogation
	# Fallback si vous avez oublié de mettre l'image
	if tex == null: tex = preload("res://icon.svg") 
	
	nouvelle_case.setup_case(tex, "?")
	
	# On appelle la fonction qu'on vient de créer dans le script de la case
	if nouvelle_case.has_method("demarrer_clignotement_mystere"):
		nouvelle_case.demarrer_clignotement_mystere()
		
	# On stocke la référence
	case_mystere_active = nouvelle_case
	
	# Scroll auto vers le bas
	await get_tree().process_frame
	var scroll_container = conteneur_cases.get_parent()
	if scroll_container is ScrollContainer:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func valider_deduction(fiche_gagnante : DonneeDeduction):
	# On vérifie si cette déduction est déjà dans l'inventaire du joueur
	if fiche_gagnante in PartieGlobale.inventaire_deductions:
		print("Déduction déjà connue : ", fiche_gagnante.titre)
		
		# 1. On cherche si on a le post-it correspondant sur la table
		if fiche_gagnante.titre in post_its_actifs_par_titre:
			var post_it_existant = post_its_actifs_par_titre[fiche_gagnante.titre]
			
			# 2. Si on a trouvé le post-it et la caméra, on agit !
			if is_instance_valid(post_it_existant) and camera_scene:
				# La caméra bouge vers le post-it
				camera_scene.focus_sur_position(post_it_existant.global_position)
				# Le post-it clignote
				post_it_existant.jouer_effet_focus()
		
		tout_reset() 
		return
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
	var nouveaux_post_its = generer_recompenses_deduction(fiche_gagnante)

	if bouton_vue_globale:
		bouton_vue_globale.declencher_feedback_positif()

	await get_tree().create_timer(1.5).timeout
	
	tout_reset()
	input_bloque = false

func tout_reset():
	selection_actuelle.clear()
	
	# Nettoyage case mystère
	if is_instance_valid(case_mystere_active):
		case_mystere_active.queue_free()
		case_mystere_active = null
		
	for indice in tous_les_indices:
		indice.deselectionner()
		retirer_case_bd(indice.id_indice)
	

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
	
func trouver_deduction_cible(liste_test: Array) -> DonneeDeduction:
	# On cherche quelle fiche contient tous les éléments actuellement sélectionnés
	for fiche in base_de_donnees_deductions:
		if est_sous_ensemble(liste_test, fiche.indices_requis):
			return fiche
	return null	
