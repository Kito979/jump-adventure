extends CharacterBody2D

@export var SPEED = 300.0  # Aumentei um pouco a velocidade para ficar melhor de ver

func _ready():
	# Não precisamos mais forçar o spawnPos e spawnRot aqui.
	# O inimigo já define a posição global antes de adicionar a bala na cena.
	pass
	
func _physics_process(delta: float):
	# Na Godot, Vector2.RIGHT (ou Vector2(1, 0)) é a frente padrão (0 graus).
	# Rotacionamos esse vetor para a rotação atual da bala.
	var direcao = Vector2.RIGHT.rotated(global_rotation)
	
	# Aplica a velocidade baseada na direção correta
	velocity = direcao * SPEED
	move_and_slide()
