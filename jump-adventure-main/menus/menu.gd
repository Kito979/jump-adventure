extends Control

# Pega a referência exata dos botões baseada na sua árvore de nós
@onready var btn_start = $MarginContainer/HBoxContainer/VBoxContainer/Btn_Start
@onready var btn_sair = $MarginContainer/HBoxContainer/VBoxContainer/Btn_Sair

func _ready() -> void:
	# 1. Garante que o botão Start já venha selecionado (ótimo para quem joga no controle/teclado)
	btn_start.grab_focus()
	
	# 2. Conecta o sinal "pressed" (clique) dos botões às nossas funções abaixo
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)

# --- FUNÇÕES DOS BOTÕES ---

func _on_btn_start_pressed() -> void:
	# Carrega a cena do jogo. 
	# ATENÇÃO: Se a sua cena "game.tscn" estiver dentro de alguma pasta, 
	# você precisa colocar o caminho completo (ex: "res://Cenas/game.tscn")
	get_tree().change_scene_to_file("res://scene/game.tscn")

func _on_btn_sair_pressed() -> void:
	# Encerra o jogo
	get_tree().quit()
