extends PanelContainer

@onready var image_rect = $VBoxContainer/TextureRect
@onready var label_texte = $VBoxContainer/Label
@onready var anim_player = $AnimationPlayer

func demarrer_clignotement_mystere():
	if anim_player:
		anim_player.play("clignotement_lent") # Le nom doit être EXACTEMENT celui de l'éditeur
	else:
		print("ERREUR : Pas d'AnimationPlayer trouvé dans CaseBD")

# Fonction pour configurer la case
func setup_case(texture_image: Texture2D, texte: String):
	if texture_image:
		image_rect.texture = texture_image
	
	label_texte.text = texte
	
	# Optionnel : Animation d'apparition "Pop"
	pivot_offset = size / 2 # Pour que ça zoom depuis le centre
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)
