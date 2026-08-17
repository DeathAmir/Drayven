extends CharacterBody2D

signal killed(points: int, position: Vector2)

var kind := "drone"
var hp := 45.0
var max_hp := 45.0
var speed := 120.0
var damage := 10.0
var points := 100
var attack_cd := 0.0
var flash := 0.0
var elite := false
var boss := false
var target: Node2D
var phase := 0.0

func setup(enemy_kind: String, difficulty: float = 1.0, is_elite: bool = false, is_boss: bool = false) -> void:
    kind = enemy_kind
    elite = is_elite
    boss = is_boss
    match kind:
        "drone":
            max_hp = 42.0; speed = 150.0; damage = 8.0; points = 90
        "stalker":
            max_hp = 62.0; speed = 210.0; damage = 12.0; points = 140
        "brute":
            max_hp = 145.0; speed = 88.0; damage = 20.0; points = 230
        "warden":
            max_hp = 240.0; speed = 105.0; damage = 24.0; points = 420
        "core_titan":
            max_hp = 1150.0; speed = 78.0; damage = 28.0; points = 3000
    max_hp *= difficulty
    if elite:
        max_hp *= 1.75
        speed *= 1.12
        damage *= 1.35
        points *= 2
    if boss:
        max_hp *= 1.25
        points *= 2
    hp = max_hp
    queue_redraw()

func _ready() -> void:
    add_to_group("enemies")
    var shape := CircleShape2D.new()
    shape.radius = 18.0 if not boss else 36.0
    var cs := CollisionShape2D.new()
    cs.shape = shape
    add_child(cs)
    target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player")
        return
    attack_cd = maxf(0.0, attack_cd - delta)
    flash = maxf(0.0, flash - delta)
    phase += delta
    var to_player := global_position.direction_to(target.global_position)
    if kind == "stalker":
        to_player = to_player.rotated(sin(phase * 4.0) * 0.32)
    velocity = to_player * speed
    move_and_slide()
    if global_position.distance_to(target.global_position) < (55.0 if boss else 34.0) and attack_cd <= 0.0:
        if target.has_method("take_damage"):
            target.take_damage(damage, global_position)
        attack_cd = 0.55 if kind == "stalker" else 0.9
    queue_redraw()

func take_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    hp -= amount
    flash = 0.08
    if source != Vector2.ZERO:
        velocity += source.direction_to(global_position) * (80.0 if not boss else 20.0)
    if hp <= 0.0:
        var p := get_tree().get_first_node_in_group("player")
        if p and p.has_method("register_kill"):
            p.register_kill(points)
        killed.emit(points, global_position)
        queue_free()

func _draw() -> void:
    var c := Color("ff5b77")
    match kind:
        "stalker": c = Color("b96fff")
        "brute": c = Color("ff9a55")
        "warden": c = Color("ff477e")
        "core_titan": c = Color("ff315f")
    if elite:
        c = c.lightened(0.22)
    if flash > 0.0:
        c = Color.WHITE
    var r := 34.0 if boss else (24.0 if kind == "brute" or kind == "warden" else 17.0)
    draw_circle(Vector2.ZERO, r + 4.0, Color("120b16"))
    draw_circle(Vector2.ZERO, r, c)
    draw_circle(Vector2(5, -4), r * 0.32, Color("1b1024"))
    draw_line(Vector2(-r, r + 10), Vector2(r, r + 10), Color("2a1b2d"), 5.0)
    draw_line(Vector2(-r, r + 10), Vector2(-r + (r * 2.0) * clampf(hp / max_hp, 0.0, 1.0), r + 10), Color("66f6d7"), 4.0)
    if elite:
        draw_arc(Vector2.ZERO, r + 8.0, 0.0, TAU, 28, Color("ffe37c"), 2.0)
