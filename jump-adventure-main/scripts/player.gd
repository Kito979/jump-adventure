extends CharacterBody2D #Herda de um nó físico com colisão

const SPEED = 300.0 #Velocidade horizontal 
const SPEED_RUN = 600 
const JUMP_VELOCITY = -400.0 #Força do pulo (negativo = para cima)

func _physics_process(delta: float) -> void: 
#Dentro do "_physics_process(delta)" essa função roda todo frame, sincronizada com a física do jogo.

	if not is_on_floor(): #Aplica gravidade quando o personagem está no ar
		velocity += get_gravity() * delta

	#Pulo ao pressionar espaço ou enter só se estiver no chão.
	if Input.is_action_just_pressed("pular") and is_on_floor(): 
		velocity.y = JUMP_VELOCITY
		
	#Pulo ao pressionar botao A do contole.
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and is_on_floor(): 
		velocity.y = JUMP_VELOCITY

	#Movimento horizontal com ← →, ou direcional direito ou esquerdo.
	var direction := Input.get_axis("esquerda", "direita")
	if direction: #se estiver precionado.
		velocity.x = direction * SPEED #personagem se move.
	else:
		velocity.x = move_toward(velocity.x, 0, 15) #persoagem fica parado e suavisa a parada do movimento.
	
	move_and_slide()
