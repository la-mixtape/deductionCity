extends Resource
class_name DonneeObjectif

@export var titre_question_verte : String = ""   # Le texte EXACT du post-it vert cible
@export var reponses_jaunes_requises : Array[String] = [] # Les textes des post-its jaunes à coller dessus
@export_multiline var texte_resolution : String = "Affaire classée." # Texte final (optionnel)
