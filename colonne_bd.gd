extends ScrollContainer

var scene_case_bd = preload("res://CaseBD.tscn")
# Dictionnaire pour garder une trace des cases créées {id_indice : noeud_case}
var cases_actives = {} 

func ajouter_case(id_indice: String, texture: Texture2D, texte: String):
	# Si la case existe déjà, on ne fait rien
	if id_indice in cases_actives:
		return
		
	var nouvelle_case = scene_case_bd.instantiate()
	add_child(nouvelle_case)
	nouvelle_case.setup_case(texture, texte)
	
	# On stocke la référence pour pouvoir la supprimer plus tard si besoin
	cases_actives[id_indice] = nouvelle_case

func retirer_case(id_indice: String):
	if id_indice in cases_actives:
		var case_a_supprimer = cases_actives[id_indice]
		cases_actives.erase(id_indice)
		case_a_supprimer.queue_free()
