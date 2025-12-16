extends TextureRect

var cible : CanvasItem = null
var marge : float = 50.0 # Marge par rapport au bord de l'écran

func definir_cible(nouvelle_cible : CanvasItem):
	cible = nouvelle_cible
	visible = true

func _process(delta):
	if not is_instance_valid(cible):
		visible = false
		return

	# Cette fonction existe bien sur CanvasItem, donc tout fonctionne !
	var position_cible_ecran = cible.get_global_transform_with_canvas().origin
	
	# ... Le reste du code est inchangé ...
	var taille_ecran = get_viewport_rect().size
	var est_dans_ecran = get_viewport_rect().has_point(position_cible_ecran)
	
	if est_dans_ecran:
		visible = false
	else:
		visible = true
		var x_bloque = clamp(position_cible_ecran.x, marge, taille_ecran.x - marge)
		var y_bloque = clamp(position_cible_ecran.y, marge, taille_ecran.y - marge)
		position = Vector2(x_bloque, y_bloque)
		
		var centre_ecran = taille_ecran / 2
		var direction = position_cible_ecran - centre_ecran
		rotation = direction.angle()
