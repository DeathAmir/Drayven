extends Area2D

const BULLET_TEXTURE := preload("res://assets/vendor/items/fireball.png")
var direction := Vector2.RIGHT
var speed := 900.0
var damage := 20.0
var life := 1.7
var explosive := false
var owner_player = null

func _ready() -> void:
    var shape := CircleShape2D.new(); shape.radius = 6.0 if not explosive else 10.0
    var collider := CollisionShape2D.new(); collider.shape = shape; add_child(collider)
    var sprite := Sprite2D.new(); sprite.texture = BULLET_TEXTURE; sprite.scale = Vector2(0.25,0.25) if not explosive else Vector2(0.42,0.42); add_child(sprite)
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    rotation = direction.angle()
    life -= delta
    if life <= 0.0: queue_free()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"): return
    if body.has_method("take_damage"):
        body.take_damage(damage, global_position)
        if owner_player: owner_player.register_hit(damage)
        if explosive:
            for target in get_tree().get_nodes_in_group("enemies"):
                if is_instance_valid(target) and target != body and target.global_position.distance_to(global_position) < 95.0:
                    target.take_damage(damage * 0.55, global_position)
        queue_free()
