extends Node

# C'est ici qu'on stocke les déductions pour tout le jeu
var inventaire_deductions : Array[DonneeDeduction] = []

func ajouter_deduction(nouvelle_deduction : DonneeDeduction):
	if not nouvelle_deduction in inventaire_deductions:
		inventaire_deductions.append(nouvelle_deduction)
		print("Inventaire Global : Ajouté " + nouvelle_deduction.titre)
