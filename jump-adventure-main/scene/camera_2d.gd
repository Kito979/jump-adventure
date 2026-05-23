# Script responsável pelo sistema de zoom da câmera
extends Camera2D

# Define o zoom padrão (1.0 = tamanho normal da tela)
const normal_zoom: Vector2 = Vector2(1.8, 1.8)

# Define o zoom afastado (0.5 = metade do tamanho, visão mais distante)
const zoom_out: Vector2 = Vector2(0.7, 0.7)

# Velocidade da transição entre os níveis de zoom
const zoom_speed: float = 2.0

# Armazena o zoom que a câmera deve atingir (alvo da interpolação)
var target_zoom: Vector2


func _ready() -> void:
	# Define o zoom alvo como o zoom normal ao iniciar o jogo
	target_zoom = normal_zoom
	# Aplica o zoom normal imediatamente na câmera ao iniciar
	zoom = normal_zoom


func _process(delta: float) -> void:
	# Enquanto a tecla "-" estiver pressionada, o alvo volta ao zoom normal (aproxima)
	if Input.is_action_pressed("zoom-"):
		target_zoom = normal_zoom

	# Enquanto a tecla "+" estiver pressionada, o alvo vai para o zoom afastado
	elif Input.is_action_pressed("zoom+"):
		target_zoom = zoom_out

	# Interpola suavemente o zoom atual em direção ao zoom alvo a cada frame
	# delta * zoom_speed controla a velocidade da transição
	zoom = zoom.lerp(target_zoom, delta * zoom_speed)
