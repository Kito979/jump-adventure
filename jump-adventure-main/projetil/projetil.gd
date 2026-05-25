extends CharacterBody2D

@export var SPEED = 300.0  # Velocidade do projétil
@export var dano: int = 1  # Quantidade de dano que causará ao acertar

func _ready():
	# Configura um relógio de 30 segundos para destruir a bala caso ela voe para o infinito
	var timer_de_vida = Timer.new()
	timer_de_vida.wait_time = 30.0
	timer_de_vida.one_shot = true
	timer_de_vida.autostart = true
	
	# Quando o tempo acabar, ele chama a função "destruir"
	timer_de_vida.timeout.connect(destruir) 
	add_child(timer_de_vida)
	
func _physics_process(_delta: float):
	# Na Godot, Vector2.RIGHT (ou Vector2(1, 0)) é a frente padrão (0 graus).
	# Rotacionamos esse vetor para a rotação atual da bala.
	var direcao = Vector2.RIGHT.rotated(global_rotation)
	
	# Aplica a velocidade baseada na direção correta
	velocity = direcao * SPEED
	
	# O move_and_slide() move o corpo e retorna 'true' se bater em algo (parede, player, chão)
	var colidiu = move_and_slide()
	
	if colidiu:
		processar_impacto()

# --- SISTEMA DE IMPACTO ---

func processar_impacto():
	# Verifica tudo em que a bala encostou neste frame de física
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo_atingido = colisao.get_collider()
		
		# Checa se o objeto que a bala bateu possui a função que criamos no script do Player
		if corpo_atingido and corpo_atingido.has_method("tomar_dano"):
			# Passa o valor do dano e a posição atual da bala para calcular o knockback no player
			corpo_atingido.tomar_dano(dano, global_position)
		
		# Independente do que for (parede, teto, inimigo ou player), a bala se destrói ao bater
		destruir()
		
		# Para o loop de verificações, pois a bala já cumpriu seu propósito
		break 

func destruir():
	queue_free()
