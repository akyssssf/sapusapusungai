extends Camera2D
## Kamera Map 3: membingkai DUA ikan sekaligus, bukan mengikuti satu.
##
## Ini bukan kemewahan. Puzzle-nya menuntut pemain menahan dua ikan di tempat
## yang sama; kalau kamera cuma mengikuti ikan yang sedang dikendalikan, ikan
## satunya hilang dari layar tepat ketika pemain paling perlu tahu di mana dia.
## Pemain akan mengendalikan sesuatu yang tidak bisa dilihatnya.
##
## Jadi kamera duduk di titik tengah keduanya, lalu menjauh secukupnya supaya
## dua-duanya tetap masuk bingkai.

@export var targets: Array[NodePath] = []
## Ruang kosong di sekeliling ikan terjauh, dalam piksel.
@export var frame_padding: float = 260.0
## Zoom terdekat dan terjauh. Di bawah 1.0 berarti pandangan makin luas.
## Batas dekat sengaja jauh lebih rendah daripada Bab 1-2, dan itu bukan
## kelalaian: Sokoban menuntut pemain melihat TATA LETAK papannya. Zoom 1,85
## sempat dicoba dan hasilnya cuma memperlihatkan lima petak -- balok yang mau
## didorong berikutnya sudah di luar layar, jadi puzzle-nya tidak bisa
## direncanakan sama sekali.
@export var zoom_range: Vector2 = Vector2(1.2, 0.85)
@export var follow_speed: float = 4.5
@export var zoom_speed: float = 2.6
@export var shake_decay: float = 42.0

var _nodes: Array[Node2D] = []
var _shake: float = 0.0


func _ready() -> void:
	for path in targets:
		var node := get_node_or_null(path) as Node2D
		if node != null:
			_nodes.append(node)
	if not _nodes.is_empty():
		global_position = _midpoint()
	zoom = Vector2.ONE * zoom_range.x


func _process(delta: float) -> void:
	if _nodes.is_empty():
		return

	global_position = global_position.lerp(_midpoint(), clampf(follow_speed * delta, 0.0, 1.0))

	# Jarak antar ikan menentukan seberapa jauh kamera harus mundur. Dibandingkan
	# dengan lebar layar dasar (1280), bukan lebar viewport saat ini, supaya
	# hasilnya sama di layar mana pun.
	var span := _span() + frame_padding
	var needed := clampf(1280.0 / maxf(span, 1.0), zoom_range.y, zoom_range.x)
	var current := lerpf(zoom.x, needed, clampf(zoom_speed * delta, 0.0, 1.0))
	zoom = Vector2(current, current)

	if _shake > 0.0:
		_shake = maxf(_shake - shake_decay * delta, 0.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	elif not offset.is_zero_approx():
		offset = Vector2.ZERO


func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _midpoint() -> Vector2:
	var total := Vector2.ZERO
	var count := 0
	for node in _nodes:
		if is_instance_valid(node):
			total += node.global_position
			count += 1
	if count == 0:
		return global_position
	return total / float(count)


## Sisi terpanjang dari kotak yang memuat semua ikan.
func _span() -> float:
	if _nodes.size() < 2:
		return 0.0
	var rect := Rect2(_nodes[0].global_position, Vector2.ZERO)
	for node in _nodes:
		if is_instance_valid(node):
			rect = rect.expand(node.global_position)
	return maxf(rect.size.x, rect.size.y * (1280.0 / 720.0))
