extends Sprite2D
## Membuat tanaman air bergoyang pelan mengikuti arus.
##
## Syaratnya satu: sprite harus dipasang dengan offset ke atas (offset.y sekitar
## -64) dan node-nya diletakkan tepat di AKAR tanaman. Dengan begitu rotasi
## berputar di pangkal seperti tumbuhan sungguhan, bukan di tengah batang.
##
## Efek sekecil ini yang membedakan latar yang "hidup" dari latar yang terasa
## seperti gambar tempel: mata manusia langsung curiga pada apa pun yang diam
## sempurna di dalam air.

@export var sway_deg: float = 5.0
@export var sway_speed: float = 1.0
## Goyangan kedua yang lebih cepat dan kecil, supaya iramanya tidak terlalu
## rapi seperti metronom.
@export var flutter_deg: float = 1.6
@export var flutter_speed: float = 3.7

var _phase: float = 0.0


func _ready() -> void:
	# Fase acak: tanpa ini seluruh tanaman di sungai bergoyang serempak.
	_phase = randf() * TAU


func _process(delta: float) -> void:
	_phase += delta
	rotation = deg_to_rad(sway_deg) * sin(_phase * sway_speed) \
		+ deg_to_rad(flutter_deg) * sin(_phase * flutter_speed)
