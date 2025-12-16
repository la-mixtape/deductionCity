extends TextureRect

var cible : CanvasItem = null
var temps_restant : float = 0.0
var duree_affichage : float = 1.0 # Durée en secondes

func _ready():
	visible = false
	set_process(false) # On désactive le calcul pour économiser des ressources

func definir_cible(nouvelle_cible : CanvasItem):
	cible = nouvelle_cible
	
	# On réinitialise le timer et on lance la machine
	temps_restant = duree_affichage
	set_process(true)
	
	# Important : On centre le pivot de la flèche sur elle-même
	# pour qu'elle tourne proprement autour de son centre
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
	# On calcule une marge de sécurité basée sur la taille de la flèche
	# (On prend la moitié de la plus grande dimension pour être sûr qu'elle rentre)
	var marge_securite = max(size.x, size.y) * scale.x / 2.0 + 20.0
	
	var x_bloque = clamp(pos_cible.x, marge_securite, rect_ecran.size.x - marge_securite)
	var y_bloque = clamp(pos_cible.y, marge_securite, rect_ecran.size.y - marge_securite)
	
	position = Vector2(x_bloque, y_bloque)
	
	# --- ROTATION ---
	var centre_ecran = rect_ecran.size / 2.0
	var direction = pos_cible - centre_ecran
	
	# On ajoute +90 degrés (PI/2 radians) car votre asset pointe vers le HAUT
	# et Godot considère que 0° est à DROITE.
	rotation = direction.angle() + PI / 2

func cacher_fleche():
	visible = false
	set_process(false)
