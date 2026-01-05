extends Resource
class_name DonneeDeduction

# Le titre servira plus tard pour l'interface (ex: "Meurtre au chandelier")
@export var titre : String = "Nouvelle Déduction"

# La liste des IDs nécessaires (ex: "couteau", "sang")
@export var indices_requis : Array[String] = []

@export_group("Récompenses (Résultats)")
@export_multiline var conclusions_jaunes : Array[String] = [] # Liste des post-its jaunes à générer
@export_multiline var questions_vertes : Array[String] = []   # Liste des post-its verts à générer

# (Optionnel) On pourra ajouter une icône ou une description ici plus tard
@export_multiline var description_victoire : String = ""
