extends Area2D

var kind := "shard"
var amount := 1
var phase := 0.0

func setup(k: String, a: int = 1) -> void:
    kind = k
    amount = a

func _ready() -> void:
    var shape := CircleShape2D.new()
    shape.radius = 13.0
    var cs := CollisionShape2D.new()
    cs.shape = shape
    add_child(cs)
    collision_layer = 0
    collision_mask = 2
    body_entered.connect(_on_body)

func _process(delta: float) -> void:
    phase += delta
    rotation += delta * 1.8
    position.y += sin(phase * 3.0) * 0.08
    queue_redraw()

func _on_body(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    match kind:
        "shard": GameState.add_shards(amount)
        "heal": body.heal(float(amount))
    queue_free()

func _draw() -> void:
    var c := Color("62e9ff") if kind == "shard" else Color("63f5a2")
    var pts := PackedVector2Array([Vector2(0,-12), Vector2(9,0), Vector2(0,12), Vector2(-9,0)])
    draw_colored_polygon(pts, c)
    draw_polyline(PackedVector2Array([Vector2(0,-12), Vector2(9,0), Vector2(0,12), Vector2(-9,0), Vector2(0,-12)]), Color.WHITE, 2.0)
