extends CharacterBody2D # Herda de um nó físico com colisão

@export var HPmax: int = 5
@onready var HP: int = HPmax # Começa com a vida cheia
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 300.0 # Velocidade horizontal
const SPEED_RUN = 600.0
const JUMP_VELOCITY = -400.0 # Força do pulo (negativo = para cima)

# --- VARIÁVEIS ANTIGAS ---
# Coyote Time
var coyote_time: float = 0.15 # Tempo de "tolerância" em segundos após cair da beirada
var coyote_timer: float = 0.0

# Dano e Invulnerabilidade
var is_invulnerable: bool = false
var is_knocked_back: bool = false
var knockback_force: Vector2 = Vector2(300, -250) # Força do recuo (X, Y)

# Timers criados via código
var invulnerability_timer = Timer.new()
var knockback_timer = Timer.new()

# --- VARIÁVEIS DE ATAQUE ---
@export var attack_damage: int = 1
@onready var attack_area: Area2D = $Area2D # Pega a Area2D da sua cena

# --- NOVA REFERÊNCIA DE DEPURAÇÃO ---
# Esta linha pega o nó visual que você criou.
# Se o seu nó tiver outro nome, altere-o aqui.
@onready var debug_visualizer: ColorRect = $Area2D/DebugVisualizer

var is_attacking: bool = false
var attack_timer = Timer.new()

func _ready() -> void:
	# Configurando o Timer de Invulnerabilidade (Intangível)
	invulnerability_timer.wait_time = 1.0 # 1 segundo de imortalidade
	invulnerability_timer.one_shot = true
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	add_child(invulnerability_timer)
	
	# Configurando o Timer do Knockback (Perda de controle ao tomar dano)
	knockback_timer.wait_time = 0.3 # 0.3 segundos sendo jogado para trás
	knockback_timer.one_shot = true
	knockback_timer.timeout.connect(_on_knockback_timeout)
	add_child(knockback_timer)
	
	# Configurando o Timer de Ataque (Cooldown)
	attack_timer.wait_time = 0.4 # Tempo de duração do ataque (ajuste conforme a animação)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timeout)
	add_child(attack_timer)
	
	# --- DEPURAÇÃO INICIAL ---
	# Certifica que o visualizador começa invisível
	debug_visualizer.visible = false

func _physics_process(delta: float) -> void: 
	# 1. GRAVIDADE E COYOTE TIME
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		velocity += get_gravity() * delta
		coyote_timer -= delta

	# 2. CONTROLE DE RECUO (KNOCKBACK)
	if is_knocked_back:
		move_and_slide()
		return

	# 3. CONTROLE DE ATAQUE
	if Input.is_action_just_pressed("Atacar") and not is_attacking:
		atacar()

	# 4. PULO COM COYOTE TIME
	var apertou_pular = Input.is_action_just_pressed("pular") or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	
	if apertou_pular and coyote_timer > 0.0: 
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0 # Zera o timer para evitar "pulo duplo" no ar
		
	# 5. MOVIMENTO HORIZONTAL
	var direction := Input.get_axis("esquerda", "direita")
	
	if direction: 
		velocity.x = direction * SPEED
		
		# Inverte o sprite dependendo da direção
		if direction < 0:
			animacao.flip_h = true
		elif direction > 0:
			animacao.flip_h = false
			
	else:
		velocity.x = move_toward(velocity.x, 0, 15) 
	
	move_and_slide()

	# 6. CONTROLE DE ANIMAÇÕES
	if is_attacking:
		animacao.play("dacando")
	elif not is_on_floor() and coyote_timer <= 0.0:
		animacao.play("pulando")
	elif direction != 0:
		animacao.play("andando")
	else:
		animacao.play("parado")

# --- SISTEMA DE DANO E INTANGIBILIDADE ---

func tomar_dano(quantidade: int, posicao_fonte: Vector2):
	if is_invulnerable:
		return
		
	HP -= quantidade
	print("Vida atual: ", HP)
	
	if HP <= 0:
		morrer()
		return
		
	is_invulnerable = true
	is_knocked_back = true
	modulate.a = 0.5 
	
	set_collision_mask_value(2, false) 
	
	invulnerability_timer.start()
	knockback_timer.start()
	
	var direcao_dano = sign(global_position.x - posicao_fonte.x)
	if direcao_dano == 0:
		direcao_dano = 1 
		
	velocity.x = knockback_force.x * direcao_dano
	velocity.y = knockback_force.y

# --- SISTEMA DE ATAQUE ---

func atacar():
	is_attacking = true
	attack_timer.start()
	
	# --- DEPURAÇÃO DE HITBOX: INÍCIO DO ATAQUE ---
	# Esta linha torna o visualizador visível.
	# >>> COMENTE A LINHA ABAIXO NA VERSÃO FINAL <<<
	debug_visualizer.visible = true
	# ---------------------------------------------
	
	# Pega todos os corpos que estão dentro da Area2D
	var corpos_na_area = attack_area.get_overlapping_bodies()
	
	for corpo in corpos_na_area:
		if corpo == self:
			continue
			
		if corpo.has_method("tomar_dano"):
			corpo.tomar_dano(attack_damage, global_position)

# --- FUNÇÕES QUE ZERAM OS EFEITOS (CHAMADAS PELOS TIMERS) ---

func _on_invulnerability_timeout():
	is_invulnerable = false
	modulate.a = 1.0 
	set_collision_mask_value(2, true) 

func _on_knockback_timeout():
	is_knocked_back = false
	
func _on_attack_timeout():
	# --- DEPURAÇÃO DE HITBOX: FIM DO ATAQUE ---
	# Esta linha torna o visualizador invisível novamente.
	# >>> COMENTE A LINHA ABAIXO NA VERSÃO FINAL <<<
	debug_visualizer.visible = false
	# ---------------------------------------------
	
	is_attacking = false

func morrer():
	print("O Jogador Morreu!")
	
	modulate.a = 1.0
	set_collision_mask_value(2, true)
	
	get_tree().change_scene_to_file("res://menus/menu.tscn")
