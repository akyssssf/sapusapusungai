extends Area2D
## Sampah yang dimuntahkan Induk Sapu-Sapu.
##
## Punya dua nyawa dalam satu benda:
##   CEPAT  -> peluru. Menyentuhnya mengurangi nyawa pemain.
##   LAMBAT -> sampah biasa. Boleh dimakan, memberi skor.
##
## Pergantiannya ditandai warna: merah menyala saat berbahaya, memudar jadi
## putih kusam saat sudah aman. Ini yang membuat fase semburan bukan cuma
## "menghindar sambil menunggu", tapi juga peluang mengejar skor.

signal became_harmless

@export var score_value: int = 25
## Di atas kecepatan ini benda dianggap peluru.
@export var danger_speed: float = 220.0
## Perlambatan air, piksel per detik kuadrat.
@export var drag: float = 520.0
## Umur maksimum sebelum dibuang sendiri, supaya tidak menumpuk selamanya.
@export var lifetime: float = 7.0

var velocity: Vector2 = Vector2.ZERO

var _dangerous: bool = true
var _consumed: bool = false
var _age: float = 0.0

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("boss_spit")
	_visual.rotation = randf() * TAU
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	velocity = velocity.move_toward(Vector2.ZERO, drag * delta)
	position += velocity * delta
	_visual.rotation += delta * 3.0

	if _dangerous and velocity.length() <= danger_speed:
		_become_harmless()


func _become_harmless() -> void:
	_dangerous = false
	became_harmless.emit()
	# Warna merah dilepas pelan-pelan, bukan langsung, supaya pemain sempat
	# membaca perubahannya dan tidak merasa dicurangi ke arah mana pun.
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(0.92, 0.94, 0.96), 0.35)


func _on_body_entered(body: Node2D) -> void:
	if _consumed or not body.is_in_group("player"):
		return

	if _dangerous:
		body.take_damage(1, global_position)
		_consumed = true
		set_deferred("monitoring", false)
		_pop()
		return

	# Sudah melambat: jadi makanan.
	_consumed = true
	set_deferred("monitoring", false)
	GameState.add_score(score_value)
	body.camera.shake(4.0)
	AudioManager.play("eat_small", -2.0, 1.25)
	_pop()


func _pop() -> void:
	set_physics_process(false)
	var tween := create_tween().set_parallel()
	tween.tween_property(_visual, "scale", Vector2.ZERO, 0.16).set_ease(Tween.EASE_IN)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)
