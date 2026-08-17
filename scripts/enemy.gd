extends CharacterBody2D

signal killed(points: int, position: Vector2)

const TEX := {
    "drone": preload("res://assets/vendor/enemies/enemyBlack1.png"),
    "stalker": preload("res://assets/vendor/enemies/enemyBlue2.png"),
    "brute": preload("res://assets/vendor/enemies/enemyRed3.png"),
    "warden": preload("res://assets/vendor/enemies/enemyGreen4.png"),
    "core_titan": preload("res://assets/vendor/enemies/enemyRed5.png")
}

var kind := "drone"
var hp := 45.0
var max_hp := 45.0
var speed := 120.0
var damage := 10.0
var points := 100
var attack_cd := 0.0
var elite := false
var boss := false
var target: Node2D
var sprite: Sprite2D

func setup(enemy_kind: String, difficulty: float = 1.0, is_elite: bool = false, is_boss: bool = false) -> void:
    kind = enemy_kind
    elite = is_elite
    boss = is_boss
    match kind:
        "drone": max_hp = 42.0; speed = 150.0; damage = 8.0; points = 90
        "stalker": max_hp = 64.0; speed = 205.0; damage = 12.0; points = 140
        "brute": max_hp = 145.0; speed = 90.0; damage = 20.0; points = 230
        "warden": max_hp = 250.0; speed = 108.0; damage = 24.0; points = 420
        "core_titan": max_hp = 1250.0; speed = 82.0; damage = 29.0; points = 3200
    max_hp *= difficulty
    if elite:
        max_hp *= 1.7; speed *= 1.12; damage *= 1.3; points *= 2
    if boss:
        max_hp *= 1.35; points *= 2
    hp = max_hp
    if sprite: _apply_visual()

func _ready() -> void:
    add_to_group("enemies")
    var shape := CircleShape2D.new(); shape.radius = 24.0 if not boss else 43.0
    var cs := CollisionShape2D.new(); cs.shape = shape; add_child(cs)
    sprite = Sprite2D.new(); add_child(sprite); _apply_visual()
    target = get_tree().get_first_node_in_group("player")

func _apply_visual() -> void:
    sprite.texture = TEX.get(kind, TEX["drone"])
    var base := 0.48 if not boss else 0.88
    sprite.scale = Vector2(base, base)
    if elite: sprite.modulate = Color(1.0, 0.88, 0.45)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player")
        return
    attack_cd = maxf(0.0, attack_cd - delta)
    var d := global_position.direction_to(target.global_position)
    velocity = d * speed
    rotation = d.angle() + PI / 2.0
    move_and_slide()
    if global_position.distance_to(target.global_position) < (64.0 if boss else 38.0) and attack_cd <= 0.0:
        target.take_damage(damage, global_position)
        attack_cd = 0.75

func take_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    hp -= amount
    if source != Vector2.ZERO: velocity += source.direction_to(global_position) * (60.0 if not boss else 15.0)
    if sprite:
        sprite.modulate = Color.WHITE if not elite else Color(1.0,0.88,0.45)
    if hp <= 0.0:
        var p := get_tree().get_first_node_in_group("player")
        if p: p.register_kill(points)
        killed.emit(points, global_position)
        queue_free()
