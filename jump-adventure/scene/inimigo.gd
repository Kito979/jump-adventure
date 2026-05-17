extends CharacterBody2D

@export var speed: float = 100.0
@export var bullet_scene: PackedScene
@export var stop_distance: float = 180.0  # Distância ideal para parar
@export var flee_distance: float = 90.0   # Distância que faz ele fugir
@export var player_path: NodePath

# Seus RayCasts e Timers
@onready var ver_flor = $VerFlor
@onready var procura_player = $Procura_Player
@onready var shoot_timer = $ShootTimer
@onready var player = get_node_or_null(player_path)

# Variáveis de controle
var direcao_olhar: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda
var jogador_detectado: bool = false

# Guarda o comprimento (alcance) original do RayCast do editor
var alcance_visao: float

func _ready():
	shoot_timer.wait_time = 1.0
	shoot_timer.one_shot = true
	
	# Salva o comprimento original do vetor usando o método .length()
	alcance_visao = procura_player.target_position.length()
	
	# IMPORTANTE: Evita que o RayCast colida com o próprio inimigo
	procura_player.add_exception(self)

func _physics_process(delta):
	# 1. GRAVIDADE
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	# 2. SE REDIRECIONAR AO JOGADOR (Olhar e girar o RayCast)
	apontar_visao_para_jogador()

	# 3. SENSOR PROCURA_PLAYER (Visão com detecção de obstáculos)
	if procura_player.is_colliding():
		var colisor = procura_player.get_collider()
		
		# Só detecta se o PRIMEIRO objeto que o raio atingir for o jogador
		if colisor and colisor.is_in_group("player"):
			jogador_detectado = true
			atirar()
		else:
			# Se colidiu com uma parede ou outra coisa antes do player, ele perde o rastro
			jogador_detectado = false
	else:
		# Se não colidiu com nada, o jogador está fora do alcance ou escondido
		if player and global_position.distance_to(player.global_position) > stop_distance * 2:
			jogador_detectado = false

	# 4. MÁQUINA DE ESTADOS (Movimentação)
	if jogador_detectado and player:
		processar_combate()
	else:
		processar_patrulha()

	move_and_slide()

# --- FUNÇÃO QUE GIRA O RAYCAST NA DIREÇÃO DO PLAYER ---
func apontar_visao_para_jogador():
	if player:
		# 1. Pega o vetor de direção normalizado (tamanho 1) apontando pro player
		var direcao_para_player = global_position.direction_to(player.global_position)
		
		# 2. Multiplica a direção pelo alcance original. 
		# Isso faz o RayCast girar em 360° mantendo rigorosamente o mesmo tamanho!
		procura_player.target_position = direcao_para_player * alcance_visao
		
		# Atualiza a direção do olhar (para a patrulha/animação saberem o lado)
		if direcao_para_player.x != 0:
			direcao_olhar = sign(direcao_para_player.x)
	
	# Atualiza a posição do VerFlor (chão) para ficar à frente do movimento
	ver_flor.position.x = direcao_olhar * abs(ver_flor.position.x)

# --- ESTADO DE PATRULHA ---
func processar_patrulha():
	ver_flor.force_raycast_update()
	
	# Se chegar na borda ou bater em parede, muda de lado
	if not ver_flor.is_colliding() or is_on_wall():
		direcao_olhar *= -1.0
		# Se não houver jogador, faz o RayCast olhar para a direção da patrulha
		if not player:
			procura_player.target_position = Vector2(direcao_olhar * alcance_visao, 0)
	
	# Se não tiver player por perto, mantém a visão horizontal na patrulha
	if not jogador_detectado:
		procura_player.target_position = Vector2(direcao_olhar * alcance_visao, 0)
		
	velocity.x = direcao_olhar * (speed * 0.6)

# --- ESTADO DE COMBATE ---
func processar_combate():
	var direction_to_player = global_position.direction_to(player.global_position)
	var distance = global_position.distance_to(player.global_position)
	var move_dir_x = 0.0

	# Determina se avança, foge ou para
	if distance < flee_distance:
		move_dir_x = -sign(direction_to_player.x) # Foge
	elif distance > stop_distance:
		move_dir_x = sign(direction_to_player.x)  # Siga o player
	else:
		move_dir_x = 0.0                          # Zona de conforto

	# PREVENÇÃO DE QUEDA NO COMBATE
	if move_dir_x != 0.0:
		ver_flor.position.x = sign(move_dir_x) * abs(ver_flor.position.x)
		ver_flor.force_raycast_update()
		
		if not ver_flor.is_colliding() or is_on_wall():
			move_dir_x = 0.0

	velocity.x = move_dir_x * speed

# --- FUNÇÃO DE TIRO ---
func atirar():
	if shoot_timer.is_stopped() and bullet_scene and player:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		
		var dir = global_position.direction_to(player.global_position)
		bullet.rotation = dir.angle()
		
		get_tree().root.add_child(bullet)
		shoot_timer.start()
