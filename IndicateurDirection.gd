extends TextureRect

@export var couleur_fleche : Color = Color.RED 
var cible : CanvasItem = null
var temps_restant : float = 0.0
var duree_affichage : float = 1.0 

func _ready():
	visible = false
	set_process(false)
	self_modulate = couleur_fleche

# IMPÉRATIF : Ajoutez bien le deuxième argument ici vvv
func definir_cible(nouvelle_cible : CanvasItem, couleur : Color = Color.WHITE):
	cible = nouvelle_cible
	
	# Maintenant "couleur" existe car il est déclaré au dessus
	if couleur != Color.WHITE:
		self_modulate = couleur
	
	temps_restant = duree_affichage
	set_process(true)
	pivot_offset = size / 2.0

func _process(delta):
	# Sécurité : Si la cible (le post-it) n'existe plus
	if not is_instance_valid(cible):
		cacher_fleche()
		return

	# 1. Gestion du Timer
	temps_restant -= delta
	if temps_restant <= 0:
		cacher_fleche()
		return

	# 2. Calculs de position
	var position_cible_ecran = cible.get_global_transform_with_canvas().origin
	var rect_ecran = get_viewport_rect()
	
	# Est-ce que le post-it est visible à l'écran ?
	# On utilise "grow" pour être un peu permissif (si juste un coin dépasse, on ne montre pas la flèche)
	if rect_ecran.grow(-50).has_point(position_cible_ecran):
		visible = false
	else:
		visible = true
		actualiser_position_et_rotation(position_cible_ecran, rect_ecran)

func actualiser_position_et_rotation(pos_cible : Vector2, rect_ecran : Rect2):
	# --- POSITIONNEMENT ---
	# On calcule la demi-taille de l'image pour qu'elle ne soit pas coupée
	# (On prend la plus grande dimension pour gérer la rotation sans risque)
	var demi_taille = max(size.x, size.y) * scale.x / 2.0
	
	# On ajoute une toute petite marge (ex: 2 pixels) pour ne pas toucher le pixel du bord
	var marge_securite = demi_taille + 2.0 
	
	# On "bloque" la position x et y pour qu'elle reste dans l'écran
	var x_bloque = clamp(pos_cible.x, marge_securite, rect_ecran.size.x - marge_securite)
	var y_bloque = clamp(pos_cible.y, marge_securite, rect_ecran.size.y - marge_securite)
	
	position = Vector2(x_bloque, y_bloque)
	
	# --- ROTATION ---
	var centre_ecran = rect_ecran.size / 2.0
	var direction = pos_cible - centre_ecran
	
	# Rappel : on ajoute PI/2 (90°) car votre asset pointe vers le HAUT
	rotation = direction.angle() + PI / 2

func cacher_fleche():
	visible = false
	set_process(false)
