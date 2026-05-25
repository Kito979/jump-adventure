extends CharacterBody2D

@export var speed: float = 100.0
@export var bullet_scene: PackedScene
@export var stop_distance: float = 180.0  # Distância ideal para parar
@export var flee_distance: float = 90.0   # Distância que faz ele fugir
@export var bullet_spawn_offset: float = 30.0 # Distância que a bala nasce a partir do centro do inimigo

# --- NOVAS VARIÁVEIS DE VIDA E DANO ---
@export var max_hp: int = 3
@onready var hp: int = max_hp

# Timer para controlar o efeito visual de piscar vermelho
var color_timer = Timer.new()

# Seus RayCasts e Timers
@onready var ver_flor = $VerFlor
@onready var procura_player = $Procura_Player
@onready var shoot_timer = $ShootTimer

# --- VARIÁVEL DO PLAYER ATUALIZADA ---
var player: Node2D # Não usa mais NodePath, o código vai achar ele sozinho!

# Variáveis de controle
var direcao_olhar: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda
var jogador_detectado: bool = false
var alcance_visao: float

func _ready():
	shoot_timer.wait_time = 1.0
	shoot_timer.one_shot = true
	
	color_timer.wait_time = 0.2
	color_timer.one_shot = true
	color_timer.timeout.connect(_on_color_timeout)
	add_child(color_timer)
	
	alcance_visao = procura_player.target_position.length()
	procura_player.add_exception(self)
	
	# --- NOVO: BUSCA AUTOMÁTICA DO JOGADOR ---
	# O inimigo procura na fase inteira quem faz parte do grupo "player"
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# Se o jogador foi destruído/morreu, tenta achar de novo (caso ele dê respawn)
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

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
			jogador_detectado = false
	else:
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
		var direcao_para_player = global_position.direction_to(player.global_position)
		procura_player.target_position = direcao_para_player * alcance_visao
		
		if direcao_para_player.x != 0:
			direcao_olhar = sign(direcao_para_player.x)
	
	ver_flor.position.x = direcao_olhar * abs(ver_flor.position.x)

# --- ESTADO DE PATRULHA ---
func processar_patrulha():
	ver_flor.force_raycast_update()
	
	if not ver_flor.is_colliding() or is_on_wall():
		direcao_olhar *= -1.0
		if not player:
			procura_player.target_position = Vector2(direcao_olhar * alcance_visao, 0)
	
	if not jogador_detectado:
		procura_player.target_position = Vector2(direcao_olhar * alcance_visao, 0)
		
	velocity.x = direcao_olhar * (speed * 0.6)

# --- ESTADO DE COMBATE ---
func processar_combate():
	var direction_to_player = global_position.direction_to(player.global_position)
	var distance = global_position.distance_to(player.global_position)
	var move_dir_x = 0.0

	if distance < flee_distance:
		move_dir_x = -sign(direction_to_player.x)
	elif distance > stop_distance:
		move_dir_x = sign(direction_to_player.x) 
	else:
		move_dir_x = 0.0                          

	if move_dir_x != 0.0:
		ver_flor.position.x = sign(move_dir_x) * abs(ver_flor.position.x)
		ver_flor.force_raycast_update()
		
		if not ver_flor.is_colliding() or is_on_wall():
			move_dir_x = 0.0

	velocity.x = move_dir_x * speed

# --- FUNÇÃO DE TIRO ATUALIZADA ---
func atirar():
	if shoot_timer.is_stopped() and bullet_scene and player:
		var bullet = bullet_scene.instantiate()
		var direcao_raycast = procura_player.target_position.normalized()
		
		bullet.global_position = global_position + (direcao_raycast * bullet_spawn_offset)
		bullet.rotation = direcao_raycast.angle()
		
		get_tree().root.add_child(bullet)
		shoot_timer.start()

# ==========================================
# --- SISTEMA DE DANO E MORTE DO INIMIGO ---
# ==========================================

func tomar_dano(quantidade: int, _posicao_fonte: Vector2 = Vector2.ZERO):
	hp -= quantidade
	modulate = Color(1.0, 0.2, 0.2) 
	color_timer.start() 
	
	if hp <= 0:
		morrer()

func _on_color_timeout():
	modulate = Color(1.0, 1.0, 1.0)

func morrer():
	queue_free()
