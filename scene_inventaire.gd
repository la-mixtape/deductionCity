extends Control

# 1. On charge la scène du post-it en mémoire
var scene_post_it = preload("res://post_it.tscn")

# 2. Une variable pour savoir où revenir (on la glissera dans l'inspecteur)
@export_file("*.tscn") var chemin_scene_jeu

func _ready():
	# Au lancement de la scène, on génère les post-its
	afficher_les_deductions()

func afficher_les_deductions():
	# D'abord, on vide la grille (pour éviter les doublons si on relance)
	# On supprime tous les enfants du HFlowContainer
	for enfant in $HFlowContainer.get_children():
		enfant.queue_free()
	
	# Ensuite, on regarde dans le "Sac à dos global" (PartieGlobale)
	# (Assurez-vous d'avoir bien créé le script PartieGlobale.gd à l'étape précédente)
	for deduction in PartieGlobale.inventaire_deductions:
		creer_un_post_it(deduction)

func creer_un_post_it(donnee : DonneeDeduction):
	# A. On crée une instance (une copie) du post-it jaune
	var nouveau_post_it = scene_post_it.instantiate()
	
	# B. On l'ajoute comme enfant de la grille (HFlowContainer)
	$HFlowContainer.add_child(nouveau_post_it)
	
	# C. On utilise la fonction qu'on a codée dans PostIt.gd pour mettre le titre
	nouveau_post_it.setup_postit(donnee.titre)

# N'oubliez pas de connecter le signal "pressed" du bouton via l'éditeur !
func _on_button_pressed():
	if chemin_scene_jeu:
		get_tree().change_scene_to_file(chemin_scene_jeu)
